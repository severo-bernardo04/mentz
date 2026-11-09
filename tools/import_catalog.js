'use strict';

/**
 * Importa o catálogo oficial (tools/exercises.json) para a coleção `exercises`
 * do Firestore. Adiciona o que é novo, atualiza o que mudou e nunca apaga.
 *
 * Uso, com a chave de administrador indicada em GOOGLE_APPLICATION_CREDENTIALS:
 *   node tools/import_catalog.js --dry-run   mostra o que mudaria, sem gravar
 *   node tools/import_catalog.js             grava as mudanças
 */

const fs = require('fs');
const path = require('path');

const COLLECTION = 'exercises';
const CATALOG_FILE = path.join(__dirname, 'exercises.json');
const BATCH_LIMIT = 500;
const ID_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const REQUIRED_TEXT_FIELDS = ['name', 'nameEn', 'muscle', 'primaryMuscle'];
const LIST_FIELDS = ['highActivationMuscles', 'secondaryMuscles'];

/** Interrompe a importação se a lista tiver algum exercício inválido. */
function validateCatalog(catalog) {
  if (!Array.isArray(catalog) || catalog.length === 0) {
    throw new Error('A lista de exercícios está vazia ou inválida.');
  }

  const seenIds = new Set();

  catalog.forEach((exercise, index) => {
    const label = exercise.id || `posição ${index}`;

    if (typeof exercise.id !== 'string' || !ID_PATTERN.test(exercise.id)) {
      throw new Error(`Identificador inválido em "${label}". Use algo como supino-reto.`);
    }
    if (seenIds.has(exercise.id)) {
      throw new Error(`Identificador repetido: "${exercise.id}".`);
    }
    seenIds.add(exercise.id);

    for (const field of REQUIRED_TEXT_FIELDS) {
      if (typeof exercise[field] !== 'string' || exercise[field].trim() === '') {
        throw new Error(`Campo "${field}" obrigatório em "${label}".`);
      }
    }
    for (const field of LIST_FIELDS) {
      const value = exercise[field];
      if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) {
        throw new Error(`Campo "${field}" deve ser uma lista de textos em "${label}".`);
      }
    }
  });
}

/** Transforma em texto ignorando a ordem das chaves, para comparar documentos. */
function canonical(value) {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (value && typeof value === 'object') {
    const entries = Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${canonical(value[key])}`);
    return `{${entries.join(',')}}`;
  }
  return JSON.stringify(value);
}

/** Calcula o que fazer, comparando a lista oficial com os documentos atuais. */
function planImport(catalog, existing) {
  const plan = { toAdd: [], toUpdate: [], unchanged: [], onlyInFirestore: [] };
  const catalogIds = new Set(catalog.map((exercise) => exercise.id));

  for (const { id, ...fields } of catalog) {
    if (!existing.has(id)) {
      plan.toAdd.push({ id, fields });
    } else if (canonical(existing.get(id)) !== canonical(fields)) {
      plan.toUpdate.push({ id, fields });
    } else {
      plan.unchanged.push(id);
    }
  }

  for (const id of existing.keys()) {
    if (!catalogIds.has(id)) plan.onlyInFirestore.push(id);
  }

  return plan;
}

function printPlan(plan) {
  for (const { id } of plan.toAdd) console.log(`  + adicionar  ${id}`);
  for (const { id } of plan.toUpdate) console.log(`  ~ atualizar  ${id}`);
  for (const id of plan.onlyInFirestore) {
    console.log(`  ! fora da lista, mantido no banco: ${id}`);
  }
  console.log(
    `\nResumo: ${plan.toAdd.length} para adicionar, ` +
      `${plan.toUpdate.length} para atualizar, ` +
      `${plan.unchanged.length} iguais.`,
  );
}

/** Conecta ao Firestore com a chave indicada na variável de ambiente. */
function connect() {
  const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!keyPath) {
    throw new Error('Defina GOOGLE_APPLICATION_CREDENTIALS com o caminho da chave.');
  }

  const projectId = JSON.parse(fs.readFileSync(keyPath, 'utf8')).project_id;
  const { initializeApp, applicationDefault } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');

  initializeApp({ credential: applicationDefault(), projectId });
  console.log(`Projeto: ${projectId}`);

  return getFirestore();
}

async function readExisting(collection) {
  const snapshot = await collection.get();
  return new Map(snapshot.docs.map((doc) => [doc.id, doc.data()]));
}

/** Grava em lotes. `set` substitui o documento, removendo campos que saíram. */
async function applyPlan(db, collection, plan) {
  const writes = [...plan.toAdd, ...plan.toUpdate];

  for (let start = 0; start < writes.length; start += BATCH_LIMIT) {
    const batch = db.batch();
    for (const { id, fields } of writes.slice(start, start + BATCH_LIMIT)) {
      batch.set(collection.doc(id), fields);
    }
    await batch.commit();
  }
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const catalog = JSON.parse(fs.readFileSync(CATALOG_FILE, 'utf8'));
  validateCatalog(catalog);

  const db = connect();
  const collection = db.collection(COLLECTION);
  const plan = planImport(catalog, await readExisting(collection));

  printPlan(plan);

  if (dryRun) {
    console.log('Simulação: nada foi gravado.');
    return;
  }

  await applyPlan(db, collection, plan);
  console.log('Importação concluída.');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`Erro: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = { validateCatalog, planImport, canonical };

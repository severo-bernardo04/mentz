'use strict';

const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const { validateCatalog, planImport } = require('./import_catalog');

const valid = (overrides = {}) => ({
  id: 'supino-reto',
  name: 'Supino reto',
  nameEn: 'Bench Press',
  muscle: 'Peito',
  primaryMuscle: 'Peitoral maior',
  highActivationMuscles: ['Tríceps'],
  secondaryMuscles: [],
  ...overrides,
});

const fieldsOf = ({ id, ...fields }) => fields;

test('a lista oficial é válida e tem 18 exercícios', () => {
  const file = path.join(__dirname, 'exercises.json');
  const catalog = JSON.parse(fs.readFileSync(file, 'utf8'));

  assert.doesNotThrow(() => validateCatalog(catalog));
  assert.strictEqual(catalog.length, 18);
});

test('adiciona o que ainda não existe', () => {
  const plan = planImport([valid()], new Map());

  assert.deepStrictEqual(plan.toAdd.map((e) => e.id), ['supino-reto']);
  assert.strictEqual(plan.toUpdate.length, 0);
});

test('ignora exercício igual, mesmo com as chaves em outra ordem', () => {
  const { name, ...rest } = fieldsOf(valid());
  const existing = new Map([['supino-reto', { ...rest, name }]]);

  const plan = planImport([valid()], existing);

  assert.deepStrictEqual(plan.unchanged, ['supino-reto']);
  assert.strictEqual(plan.toAdd.length + plan.toUpdate.length, 0);
});

test('atualiza exercício alterado', () => {
  const existing = new Map([['supino-reto', fieldsOf(valid({ name: 'Antigo' }))]]);

  const plan = planImport([valid()], existing);

  assert.deepStrictEqual(plan.toUpdate.map((e) => e.id), ['supino-reto']);
});

test('atualiza quando um campo saiu da lista oficial', () => {
  const existing = new Map([['supino-reto', { ...fieldsOf(valid()), equipment: 'Barra' }]]);

  const plan = planImport([valid()], existing);

  assert.strictEqual(plan.toUpdate.length, 1);
  assert.strictEqual('equipment' in plan.toUpdate[0].fields, false);
});

test('adiciona só o exercício novo em uma nova importação', () => {
  const existing = new Map([['supino-reto', fieldsOf(valid())]]);
  const plan = planImport([valid(), valid({ id: 'remada-curvada' })], existing);

  assert.deepStrictEqual(plan.toAdd.map((e) => e.id), ['remada-curvada']);
  assert.deepStrictEqual(plan.unchanged, ['supino-reto']);
});

test('apenas avisa sobre exercício que saiu da lista', () => {
  const existing = new Map([['antigo', fieldsOf(valid())]]);

  const plan = planImport([valid()], existing);

  assert.deepStrictEqual(plan.onlyInFirestore, ['antigo']);
});

test('recusa identificador repetido ou inválido e campo faltando', () => {
  assert.throws(() => validateCatalog([valid(), valid()]), /repetido/);
  assert.throws(() => validateCatalog([valid({ id: 'Supino Reto' })]), /inválido/);
  assert.throws(() => validateCatalog([valid({ nameEn: '' })]), /nameEn/);
  assert.throws(() => validateCatalog([]), /vazia/);
});

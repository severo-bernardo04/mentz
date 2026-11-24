import 'package:flutter/material.dart';

/// Seção dos Termos de Uso (título numerado + parágrafos e/ou itens).
class TermsSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const TermsSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

/// Conteúdo dos Termos de Uso do Mentz.
abstract final class TermsOfUseContent {
  static const version = '1.0';
  static const lastUpdate = '24 de novembro de 2026';
  static const contactEmail = 'contato@mentz.app';

  static const intro =
      'Bem-vindo ao Mentz. Estes Termos de Uso regulam o acesso e a utilização '
      'do aplicativo Mentz, ferramenta de planejamento, registro e '
      'acompanhamento de treinos de musculação. Leia com atenção antes de '
      'criar sua conta. Ao marcar a opção "Li e aceito os termos de uso" e '
      'concluir o cadastro, você declara que leu, compreendeu e concorda com '
      'todas as condições abaixo.';

  static const sections = <TermsSection>[
    TermsSection(
      title: '1. Definições',
      bullets: [
        'Aplicativo: o Mentz, em todas as suas versões e funcionalidades.',
        'Usuário: a pessoa que cria uma conta e utiliza o Aplicativo.',
        'Dados pessoais: informações que identificam ou podem identificar o '
            'Usuário, conforme a Lei nº 13.709/2018 (LGPD).',
        'Dados de saúde e medidas corporais: altura, peso, data de '
            'nascimento, sexo biológico e indicadores calculados a partir '
            'deles, como IMC e percentual de gordura estimado.',
      ],
    ),
    TermsSection(
      title: '2. Objeto e finalidade',
      paragraphs: [
        'O Mentz oferece recursos para criar planilhas de treino, registrar '
            'sessões, acompanhar cargas, repetições e evolução muscular, '
            'consultar o catálogo de exercícios, registrar medidas corporais '
            'e compartilhar resultados de treino.',
        'O Aplicativo é uma ferramenta de apoio e organização. Ele não '
            'substitui a orientação de profissionais de Educação Física, '
            'nutrição ou saúde.',
      ],
    ),
    TermsSection(
      title: '3. Cadastro e conta',
      bullets: [
        'Para usar o Aplicativo é necessário criar uma conta com nome, e-mail '
            'e senha válidos.',
        'Você deve ter 18 anos ou mais. Menores de idade só podem utilizar o '
            'Aplicativo com autorização e supervisão de um responsável legal.',
        'As informações fornecidas devem ser verdadeiras, completas e '
            'atualizadas. Você é responsável por qualquer dado incorreto.',
        'Sua senha é pessoal e intransferível. Você é responsável por todas '
            'as atividades realizadas na sua conta e deve nos avisar '
            'imediatamente em caso de uso não autorizado.',
        'Data de nascimento, sexo biológico, altura e peso são opcionais no '
            'cadastro, mas necessários para o cálculo de IMC e das '
            'estimativas corporais.',
      ],
    ),
    TermsSection(
      title: '4. Aviso de saúde e responsabilidade pelo treino',
      paragraphs: [
        'A prática de atividade física envolve riscos. Antes de iniciar ou '
            'alterar qualquer programa de treino, consulte um médico e um '
            'profissional de Educação Física, principalmente se você tiver '
            'doenças, lesões, limitações físicas, estiver grávida ou tiver '
            'mais de 60 anos.',
        'Os indicadores exibidos no Aplicativo são informativos:',
      ],
      bullets: [
        'O IMC é um indicador populacional e não considera massa muscular, '
            'distribuição de gordura ou composição corporal individual.',
        'O percentual de gordura é uma ESTIMATIVA calculada pela fórmula de '
            'Deurenberg (1991), com base em IMC, idade e sexo, e classificada '
            'pela tabela do American Council on Exercise (ACE). Ela não '
            'substitui avaliação física, bioimpedância ou DEXA, e pode '
            'divergir bastante em pessoas com alta massa muscular.',
        'A faixa de peso saudável é uma referência geral e não um objetivo '
            'individual de peso.',
        'Pontuações, análises musculares e sugestões do Aplicativo não '
            'constituem prescrição de exercícios, diagnóstico ou '
            'recomendação médica ou nutricional.',
      ],
    ),
    TermsSection(
      title: '5. Uso adequado',
      paragraphs: ['Ao utilizar o Mentz, você se compromete a não:'],
      bullets: [
        'usar o Aplicativo para fins ilegais ou que violem direitos de '
            'terceiros;',
        'tentar acessar contas, dados ou sistemas sem autorização, nem '
            'explorar falhas de segurança;',
        'copiar, modificar, descompilar, revender ou distribuir o '
            'Aplicativo ou parte dele sem autorização;',
        'inserir conteúdo ofensivo, discriminatório, falso ou que viole '
            'direitos autorais;',
        'utilizar robôs, scripts ou meios automatizados que prejudiquem o '
            'funcionamento do serviço.',
      ],
    ),
    TermsSection(
      title: '6. Conteúdo do usuário e compartilhamento',
      paragraphs: [
        'Planilhas, registros de treino, medidas e fotos continuam sendo '
            'seus. Você concede ao Mentz uma licença limitada, não exclusiva '
            'e gratuita, apenas para armazenar e exibir esse conteúdo a você '
            'e às pessoas que você autorizar, no contexto do serviço.',
        'No compartilhamento de treino em formato Stories, a imagem é '
            'gerada no seu aparelho e enviada somente para o aplicativo que '
            'você escolher. Você é o único responsável pelo que publicar e '
            'declara ter direitos sobre as fotos utilizadas.',
      ],
    ),
    TermsSection(
      title: '7. Privacidade e proteção de dados (LGPD)',
      paragraphs: [
        'O tratamento dos seus dados segue a Lei Geral de Proteção de Dados '
            '(Lei nº 13.709/2018).',
      ],
      bullets: [
        'Dados coletados: nome, e-mail, dados de autenticação, planilhas e '
            'histórico de treino, medidas corporais, data de nascimento, '
            'sexo biológico e preferências do aplicativo.',
        'Finalidade: criar e manter sua conta, personalizar o '
            'acompanhamento de treino, calcular indicadores corporais, '
            'sincronizar seus dados entre aparelhos e melhorar o serviço.',
        'Dados sensíveis: medidas corporais e informações relacionadas à '
            'saúde são tratadas com base no seu consentimento, que pode ser '
            'revogado a qualquer momento.',
        'Armazenamento: os dados são armazenados em infraestrutura em '
            'nuvem com autenticação e regras de acesso por usuário.',
        'Compartilhamento: não vendemos seus dados. Eles só são acessados '
            'por prestadores de infraestrutura necessários à operação, por '
            'profissionais que você autorizar ou por determinação legal.',
        'Seus direitos: confirmar a existência de tratamento, acessar, '
            'corrigir, anonimizar, portar e eliminar dados, revogar '
            'consentimento e obter informações sobre compartilhamento, '
            'mediante solicitação pelo canal de contato.',
        'Os dados são mantidos enquanto a conta estiver ativa e podem ser '
            'preservados pelo prazo exigido por obrigação legal.',
      ],
    ),
    TermsSection(
      title: '8. Propriedade intelectual',
      paragraphs: [
        'O nome Mentz, a marca, o logotipo, o design, o código-fonte, os '
            'textos, as ilustrações e o catálogo de exercícios são protegidos '
            'pela legislação de propriedade intelectual. O uso do Aplicativo '
            'não transfere a você nenhum direito sobre eles, exceto o direito '
            'pessoal, limitado e revogável de utilizá-lo conforme estes '
            'Termos.',
      ],
    ),
    TermsSection(
      title: '9. Disponibilidade e alterações do serviço',
      paragraphs: [
        'Trabalhamos para manter o Aplicativo disponível e seguro, mas não '
            'garantimos funcionamento ininterrupto ou livre de erros. Pode '
            'haver indisponibilidades por manutenção, falhas de internet, '
            'de terceiros ou casos de força maior.',
        'Funcionalidades podem ser adicionadas, alteradas ou removidas a '
            'qualquer momento para evolução do serviço.',
      ],
    ),
    TermsSection(
      title: '10. Limitação de responsabilidade',
      paragraphs: [
        'O Mentz é fornecido "como está". Na extensão permitida pela lei, '
            'não nos responsabilizamos por:',
      ],
      bullets: [
        'lesões, danos à saúde ou resultados decorrentes da execução dos '
            'treinos registrados ou planejados no Aplicativo;',
        'decisões tomadas com base em IMC, percentual de gordura ou outras '
            'estimativas exibidas;',
        'perda de dados causada por mau uso, perda de acesso à conta ou '
            'falhas de terceiros;',
        'conteúdo publicado por você em redes sociais por meio do '
            'compartilhamento.',
      ],
    ),
    TermsSection(
      title: '11. Suspensão e encerramento',
      paragraphs: [
        'Podemos suspender ou encerrar contas que violem estes Termos, a '
            'lei ou coloquem a segurança do serviço em risco. Você pode '
            'encerrar sua conta e solicitar a exclusão dos seus dados a '
            'qualquer momento pelo canal de contato, observadas as '
            'obrigações legais de guarda.',
      ],
    ),
    TermsSection(
      title: '12. Alterações destes Termos',
      paragraphs: [
        'Estes Termos podem ser atualizados periodicamente. Em mudanças '
            'relevantes, avisaremos pelo Aplicativo. O uso continuado após a '
            'atualização indica concordância com a nova versão.',
      ],
    ),
    TermsSection(
      title: '13. Lei aplicável e foro',
      paragraphs: [
        'Estes Termos são regidos pelas leis da República Federativa do '
            'Brasil. Fica eleito o foro do domicílio do Usuário para dirimir '
            'controvérsias, conforme o Código de Defesa do Consumidor.',
      ],
    ),
    TermsSection(
      title: '14. Contato',
      paragraphs: [
        'Dúvidas, solicitações sobre dados pessoais ou reclamações podem '
            'ser enviadas para $contactEmail.',
      ],
    ),
  ];
}

/// Tela de leitura dos Termos de Uso. Retorna `true` ao tocar em
/// "Li e aceito", para que o cadastro marque o checkbox automaticamente.
class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Termos de Uso')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                child: ListView(
                  key: const Key('terms_scroll'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      'Termos de Uso do Mentz',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Versão ${TermsOfUseContent.version} • Atualizado em '
                      '${TermsOfUseContent.lastUpdate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      TermsOfUseContent.intro,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    for (final section in TermsOfUseContent.sections)
                      _SectionView(section: section),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: const Key('terms_accept_button'),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Li e aceito'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final TermsSection section;

  const _SectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.5);

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          for (final p in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p, style: body),
            ),
          for (final b in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(child: Text(b, style: body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

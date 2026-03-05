# Gerador Tamanho Logo

<p align="center">
  <img src="topo/agentbr-topo-github.png" alt="AgentBR - Gerador Tamanho Logo" width="100%">
</p>

>
> Kit rápido para gerar formatos e tamanhos usados por app e extensão./n
> Esse fluxo foi pensado para ser simples de **utilizar**.
> 👉 Formatos exportação: PNG, ICO, ICNS e SVG(com/sem fundo).
>
---

## Como usar

Detectação automática (quando existir apenas 1 imagem em `fonte/`):

```bash
cd agentbr-gerador-tamanho-logo
./scripts/gerar-assets.sh
```

Outra forma é colocar o local da imagem:

```bash
./scripts/gerar-assets.sh /caminho/da/sua-logo.png
```

Auto-instalação para **remover fundo** SVG, precisamos das dependências:
- (ImageMagick + potrace)

```bash
./scripts/gerar-assets.sh --install-deps
./scripts/gerar-assets.sh --install-deps /caminho/da/sua-logo.png
```

>
> Se houver mais de um arquivo de imagem em `fonte/`, o script para com erro e lista os arquivos encontrados para você escolher um caminho explícito.
>

## Dicas e limitações

- Se a logo não for quadrada, o redimensionamento força formato quadrado para padronizar ícones.
- PNG em `2048x2048` e válido para pacote de assets.
- SVG principal prefere versão vetorial quando `potrace` estiver disponível; se não, usa automaticamente versão embed.
- SVG vetorial via `potrace` e monocromático, podendo simplificar logos complexas.
- SVG embed preserva fidelidade visual da arte original.
- Cor do `-com-fundo.svg` é realizado a captação do canto superior esquerdo; se o canto for transparente, usa `#FFFFFF`.
- ⚠️ `.icns` é suportado apenas no macOS; em Linux/Windows o script avisa e continua.
- ⚠️ Antes de cada execução, o script limpa arquivos antigos em `saida/png`, `saida/ico`, `saida/icns` e `saida/svg` (preservando `.gitkeep`).

## Saida principal

- `saida/png/favicon-16x16.png`
- `saida/png/favicon-32x32.png`
- `saida/png/apple-touch-icon.png`
- `saida/png/android-chrome-192x192.png`
- `saida/png/android-chrome-512x512.png`
- `saida/png/tamanhos/<nome-da-logo>-16x16.png`
- `saida/png/tamanhos/<nome-da-logo>-32x32.png`
- `saida/png/tamanhos/<nome-da-logo>-64x64.png`
- `saida/png/tamanhos/<nome-da-logo>-128x128.png`
- `saida/png/tamanhos/<nome-da-logo>-256x256.png`
- `saida/png/tamanhos/<nome-da-logo>-512x512.png`
- `saida/png/tamanhos/<nome-da-logo>-1024x1024.png`
- `saida/png/tamanhos/<nome-da-logo>-2048x2048.png`
- `saida/ico/favicon.ico`
- `saida/icns/app.icns`
- `saida/svg/<nome-da-logo>-sem-fundo.svg`
- `saida/svg/<nome-da-logo>-com-fundo.svg`
- `saida/svg/<nome-da-logo>-sem-fundo-embed.svg`
- `saida/svg/<nome-da-logo>-com-fundo-embed.svg`

Quando houver vetorizacao com `potrace`, também serão gerados:

- `saida/svg/<nome-da-logo>-sem-fundo-vetor.svg`
- `saida/svg/<nome-da-logo>-com-fundo-vetor.svg`

## Estrutura

- `fonte/`: coloque a logo com qualquer nome (ex.: `agentbr-logo-fundo.png`)
- `scripts/gerar-assets.sh`: script de geração
- `saida/png/`: aliases web em PNG
- `saida/png/tamanhos/`: PNGs por tamanho em potencias de 2 (16 ate 2048)
- `saida/ico/`: `favicon.ico`
- `saida/icns/`: `app.icns` para app no macOS
- `saida/svg/`: SVG com/sem fundo, com fallback embed
- `topo/agentbr-topo-github.png`: imagem de topo para o README

---

>
> Melhoras futuras:
> - Opção de escolha de extensão,
> - Opção de escolha de tamanhos específicos,
> - Opção de alteração saída do nome dos arquivos.
> - Terminal Interativo,
> - Skill para IA's,
> - Aceitar várias imagens ao mesmo tempo,
>

---

## Ajude ao AgentBR a crescer! 🇧🇷

```markdown
Conheça nossos projetos em [SITE OFICIAL](https://agentbr.ia.br)
````

Seja um parceiro/colaborador
email:[`mailon@agentbr.ia.br`]

---

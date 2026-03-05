# AgentBR Identidade Visual

![Topo](topo/agentbr-topo-github.png)

Kit rapido para gerar icones da logo nos formatos usados por app Mac e website.

## Estrutura

- `fonte/`: coloque a logo com qualquer nome (ex.: `agentbr-logo-fundo.png`)
- `scripts/gerar-assets.sh`: script de geracao
- `saida/png/`: aliases web em PNG
- `saida/png/tamanhos/`: PNGs por tamanho em potencias de 2 (16 ate 2048)
- `saida/ico/`: `favicon.ico`
- `saida/icns/`: `app.icns` para app no macOS
- `topo/agentbr-topo-github.png`: imagem de topo para o README

## Como usar

Autodetectar (quando existir apenas 1 imagem em `fonte/`):

```bash
cd agentbr-identidade-visual
./scripts/gerar-assets.sh
```

Passando caminho explicito da imagem:

```bash
./scripts/gerar-assets.sh /caminho/da/sua-logo.png
```

Se houver mais de um arquivo de imagem em `fonte/`, o script para com erro e lista os arquivos encontrados para voce escolher um caminho explicito.

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

## Dicas

- Se a logo nao for quadrada, o `sips` pode distorcer; prefira preparar uma versao quadrada antes.
- PNG em `2048x2048` e valido para pacote de assets; o `.icns` continua limitado ao conjunto padrao ate `1024x1024`.
- Antes de cada execucao, o script limpa arquivos antigos em `saida/png`, `saida/ico` e `saida/icns` (preservando `.gitkeep`).
- Esse fluxo foi pensado para ser simples de compartilhar no GitHub e rodar em macOS sem dependencias extras.

--

Ajude ao AgentBR a crescer! 🇧🇷

--

# piloto-esteira

Modelo de esteira para mostrar o formato de um piloto de DevOps. Dois serviços, `web` e `api`, publicam a versão e o commit. O GitHub Actions testa, publica a imagem no GHCR e, quando o VPS estiver indicado, troca o tráfego só depois do healthcheck. A reversão é outro disparo manual.

Isto não é entrega de cliente. O ensaio usa imagens deste repositório.

- Operação: [RUNBOOK.md](RUNBOOK.md)
- O que entra no modelo: [CATALOGO.md](CATALOGO.md)

Os segredos `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY` e, se o SSH não for na porta 22, `VPS_PORT` ficam no repositório. Sem eles, a publicação da imagem segue e o deploy para.

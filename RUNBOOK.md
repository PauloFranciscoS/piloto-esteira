# Runbook

Quem opera a esteira não precisa pedir o passo a passo. O disparo está no GitHub, em Actions. A imagem já precisa existir: um push na `main` publica `ghcr.io/paulofranciscos/piloto-esteira-web` e `piloto-esteira-api` com a tag do commit.

A página e a API respondem atrás do NGINX. A página mostra serviço, versão e commit. `/api/version` faz o mesmo em JSON. `/health` responde 200 quando a release pode receber tráfego.

## Publicar

1. Abra Actions, workflow **deploy**, e clique em Run workflow.
2. No campo tag, cole o SHA do commit que o workflow **ci** já publicou.
3. Deixe "simular falha" desmarcado.
4. O script sobe essa tag num slot que ainda não está no ar.
5. Ele consulta `/health` do `web` e da `api` nesse slot. Os dois precisam responder 200.
6. Só então o NGINX passa a apontar para o slot novo. A tag que estava no ar vira a anterior e continua de pé para a reversão.

Se o healthcheck falha, o script derruba só o candidato. O NGINX não muda.

## Reverter

1. Abra Actions, workflow **rollback**, e clique em Run workflow.
2. Deixe a tag `previous`.
3. O script lê, no VPS, a tag da release anterior, sobe essa imagem num slot livre, repete o healthcheck e só então troca o NGINX.

Para voltar a um SHA específico, cole esse SHA no lugar de `previous`. A imagem desse SHA tem de estar no GHCR.

## Ensaio

Faça nesta ordem, com o VPS já acessível pelos segredos:

1. **deploy** com o SHA bom e sem simular falha. A página deve mostrar esse commit.
2. **deploy** de novo, com o mesmo SHA, marcando simular falha. O candidato sobe com `HEALTH_MODE=fail`, `/health` responde 500, e a página continua no commit do passo 1.
3. **rollback** com `previous`. A página volta para a release guardada antes da atual. No ensaio do passo 2 a atual não mudou, então a anterior é a de antes do passo 1, se ela existir. Para ver a volta com clareza, publique dois SHAs bons em sequência e reverta o segundo.

O que fica registrado: o log do Actions, o healthcheck que passou ou falhou, e a frase final do script com a tag que está no tráfego e a tag anterior.

## No servidor

O diretório é `/opt/piloto-esteira`. `state.env` guarda o slot e a tag atuais e os anteriores. O NGINX está no container `piloto-nginx` e lê `nginx/upstreams`. Não edite o upstream à mão. O próximo deploy reescreve o arquivo.

Os segredos do VPS ainda não estão no repositório. Enquanto isso, o workflow **deploy** existe e falha ao ser disparado, de propósito, porque não há host.

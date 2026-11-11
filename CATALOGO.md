# Catálogo

Só o que este modelo usa.

## GitHub Actions

Roda o teste a cada push na `main` e, se o teste passa, publica as duas imagens. O deploy e a reversão são disparos manuais, separados. Quem opera escolhe o workflow e a tag. Não há aprovação dentro do script para uma publicação já disparada. O healthcheck é a trava antes de trocar o tráfego.

## GHCR

Guarda `piloto-esteira-web` e `piloto-esteira-api`. A tag é o SHA do commit. O VPS baixa essa tag. Não há registro de imagem no próprio servidor.

## Docker Compose

Sobe o candidato num projeto próprio (`piloto-a`, `piloto-b` ou `piloto-c`) na rede `piloto`. O slot que recebe tráfego e o slot anterior ficam no ar. O mais antigo dos três é removido depois que o novo passa no healthcheck. Uma falha remove só o candidato.

## NGINX

Único ponto de entrada, na porta 80 do VPS. `/` vai para o `web`. `/api/` vai para a `api`. A troca de tráfego é reescrever o upstream e recarregar o NGINX. Sem domínio neste modelo, o endereço é o IP do VPS. Certificado fica para quando houver um domínio só desta apresentação.

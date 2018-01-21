docker create -v /config --name config busybox; docker cp vault.hcl config:/config/;
docker run -d --name consul      -p 8500:8500     consul:latest     agent -dev -client=0.0.0.0
docker run -d --name vault   --link consul:consul   -p 8200:8200 --cap-add IPC_LOCK --volumes-from config  vault:latest server -config=/config/vault.hcl
alias vault='docker exec -it vault vault "$@"'
vault init -address=${VAULT_ADDR} > keys.txt
vault unseal -address=${VAULT_ADDR} $(grep 'Key 1:' keys.txt | awk '{print $NF}')
vault unseal -address=${VAULT_ADDR} $(grep 'Key 2:' keys.txt | awk '{print $NF}')
vault unseal -address=${VAULT_ADDR} $(grep 'Key 3:' keys.txt | awk '{print $NF}')
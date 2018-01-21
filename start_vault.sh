docker create -v /config --name config busybox; docker cp vault.hcl config:/config/;
docker run -d --name consul      -p 8500:8500     consul:latest     agent -dev -client=0.0.0.0
docker run -d --name vault   --link consul:consul   -p 8200:8200 --cap-add IPC_LOCK --volumes-from config  vault:latest server -config=/config/vault.hcl
alias vault='docker exec -it vault vault "$@"'
docker exec -it vault "vault init -address=${VAULT_ADDR} > keys.txt"
docker exec -it vault "vault unseal -address=${VAULT_ADDR} $(grep 'Key 1:' keys.txt | awk '{print $NF}')"
docker exec -it vault "vault unseal -address=${VAULT_ADDR} $(grep 'Key 2:' keys.txt | awk '{print $NF}')"
docker exec -it vault "vault unseal -address=${VAULT_ADDR} $(grep 'Key 3:' keys.txt | awk '{print $NF}')"
export VAULT_TOKEN=$(grep 'Initial Root Token:' keys.txt | awk '{print substr($NF, 1, length($NF)-1)}')
docker exec -it vault "vault auth -address=${VAULT_ADDR} ${VAULT_TOKEN}"
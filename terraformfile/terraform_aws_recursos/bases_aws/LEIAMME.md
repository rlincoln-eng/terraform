OBJETIVO DO PROJETO: Exemplificar como é o funcionamento de 2 arquivos, sendo 1 para subir a estrutura de um bucket e o 2o para efetuar ingestão de arquivos parquet neste bucket.
<p>Utilização de terraform e python para a solução disposta.</p>
<p>Processamento local do script python.</p>


##############################################################################################
#                                                                                            #
#                          Disposição de pastas                                              #
# lab_arquivo2lake                                                                           #
# |                                                                                          #
# |-Dockerfile                                                                               #
# |                                                                                          #
# |-python                                                                                   #
#     |                                                                                      #
#     |-transformar_arquivo_parquet.py                                                       #
# |                                                                                          #
# |-IaC                                                                                      #
#    |                                                                                       #
#    |-main.tf                                                                               #
#                                                                                            #
##############################################################################################

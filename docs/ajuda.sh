# From: https://github.com/EticaAI/pt.etica.ai/blob/master/ajuda.sh
# Nao execute esse script por acidente
exit 1

## Depurar localmente
# Isso instala as dependencias do Jekyll
bundle install

# Roda o Jekyll localmente em http://localhost:4000
bundle exec jekyll serve

################# How to generate the Table of Contents (TOC) ##################
# The ToC can be generated manually. This repository use a simple automation
# with VSCode (https://code.visualstudio.com/) extension called
# "alanwalk.markdown-toc". So each time the document is saved, the ToC is
#  generated in the tags <!-- TOC --> ... <!-- /TOC -->, like this:
#
# <!-- TOC depthFrom:2 depthTo:5 -->
#   (....)
#   (... content automaticaly generated by extension)
#   (....)
# <!-- /TOC -->
################# How to generate the Table of Contents (TOC) ##################
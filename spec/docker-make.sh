# Build the Composable Custom Extensions Specification (spec.pdf)
# using riscvintl/rv-docs's asciidoctor configuration.
# Alas, this config always generates a chatty but benign warning:
#  "Warning! PATH is not properly set up, ..."
docker run --rm -u 1000 -t -i -v $(pwd):/home/dockeruser/workspace --net=host riscvintl/rv-docs /bin/bash -i -c make

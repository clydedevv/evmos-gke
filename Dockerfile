# Use the base image from Tharsis
FROM tharsishq/evmos:latest

# Set work directory
WORKDIR /home/evmos

# Copy the genesis and addrbook files into the container
COPY genesis.json /home/evmos/.evmosd/config/genesis.json
COPY addrbook.json /home/evmos/.evmosd/config/addrbook.json

# Expose necessary ports
EXPOSE 26656 26657 1317 9090 8545 8546

# Start command with minimum gas prices set
CMD ["evmosd", "start", "--minimum-gas-prices=0.025aevmos"]


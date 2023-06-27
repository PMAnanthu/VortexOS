SRC_DIR=src
BIN_DIR=bin
BUILD_DIR=build

all: clean directories compile build

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(BIN_DIR)

directories:
	mkdir $(BIN_DIR)
	mkdir $(BUILD_DIR)
	
compile: $(SRC_DIR)/boot.asm
	nasm $(SRC_DIR)/boot.asm -f bin -o $(BIN_DIR)/boot.bin

build: $(BUILD_DIR)/boot_disk.img

$(BUILD_DIR)/boot_disk.img: $(BIN_DIR)/boot.bin
	cp $(BIN_DIR)/boot.bin $(BUILD_DIR)/boot_disk.img


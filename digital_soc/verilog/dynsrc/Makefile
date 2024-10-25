CC := g++



ifeq ($(OS),Windows_NT)
	CPPFLAGS := -D_WIN32 -Id:/soft/verilator/include -I../obj_dir -shared
	DLL_EXT := .dll
	MKDIR := powershell -Command "New-Item -ItemType Directory -Force"
	RMDIR := powershell -Command "Remove-Item -Recurse -Force"
	RM := powershell -Command "Remove-Item -Recurse -Force"
else
	CPPFLAGS := -shared -fPIC
	DLL_EXT := .so
	MKDIR := mkdir -p
	RMDIR := rm -rf
	RM := rm -f
endif

LDFLAGS :=  $(CPPFLAGS)   -pthread -lpthread -latomic

all: wrapper

wrapper: wrapper.cpp
	@echo "wrapper compiled"
	@echo $(OS)
	$(CC) $(LDFLAGS) -o wrapper$(DLL_EXT) wrapper.cpp ../obj_dir/verilated.o ../obj_dir/verilated_threads.o ../obj_dir/Vdigital_soc_top__ALL.a \
	../obj_dir/verilated_vcd_c.o
	
clean:
	$(RM) wrapper$(DLL_EXT)

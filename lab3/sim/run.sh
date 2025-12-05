#!/bin/bash

# Thiết lập biến mặc định
TESTNAME=${TESTNAME:-tb_processor}
TB_NAME=${TB_NAME:-test_bench_processor}

CMD=$1

if [ -z "$CMD" ]; then
    echo "Usage: run.sh [build|run|waveform|all|clean]"
    exit 0
fi

case "$CMD" in
    "build")
        echo "[*] Compiling..."
        
        # Sao chép và đổi tên file
        # cp "../testcases/$TESTNAME.v" "run_test.v"
        
        # Biên dịch Verilog
        # Đảm bảo iverilog và file compile.f có sẵn
        iverilog -o simv -f compile.f
        
        if [ $? -ne 0 ]; then
            echo "[!] Compilation failed!"
            exit 1
        fi
        exit 0
        ;;

    "run")
        echo "[*] Running simulation..."
        
        # Chạy mô phỏng
        # Đảm bảo simv đã được tạo
        vvp simv
        
        if [ $? -ne 0 ]; then
            echo "[!] Simulation failed!"
            exit 1
        fi
        exit 0
        ;;

    "waveform")
        echo "[*] Opening waveform..."
        # Mở gtkwave
        gtkwave "$TB_NAME.vcd"
        exit 0
        ;;

    "all")
        # Gọi lệnh 'build'
        ./run.sh build
        if [ $? -ne 0 ]; then
            exit 1
        fi
        # Gọi lệnh 'run'
        ./run.sh run
        exit 0
        ;;

    "clean")
        echo "[*] Cleaning..."
        # Xóa các file được tạo ra, 2> /dev/null để ẩn lỗi nếu file không tồn tại
        rm -f simv "$TB_NAME.vcd" run_test.v 2> /dev/null
        echo "Done."
        exit 0
        ;;

    *)
        echo "Unknown command: $CMD"
        echo "Usage: run.sh [build|run|waveform|all|clean]"
        exit 1
        ;;
esac
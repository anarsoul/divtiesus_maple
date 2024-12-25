#include <stdio.h>
#include <input.h>
#include <arch/zx.h>

#define UART_DATA_REG 0xc6
#define UART_STAT_REG 0xc7
#define UART_BYTE_RECEIVED 0x80
#define UART_BUSY 0x40

__sfr __banked __at 0xfc3b ZXUNO_ADDR;
__sfr __banked __at 0xfd3b ZXUNO_REG;

static void uart_send(unsigned char c)
{
    unsigned char d;
    ZXUNO_ADDR = UART_STAT_REG;
    do {
        d = ZXUNO_REG;
    } while (d & UART_BUSY);
    ZXUNO_ADDR = UART_DATA_REG;
    ZXUNO_REG = c;
}

static unsigned char uart_read(void)
{
    unsigned char d;
    ZXUNO_ADDR = UART_DATA_REG;
    d = ZXUNO_REG;
    return d;
}

static char uart_ready(void)
{
    unsigned char d;
    ZXUNO_ADDR = UART_STAT_REG;
    d = ZXUNO_REG;
    return !!(d & UART_BYTE_RECEIVED);
}

static void uart_init(void)
{
    char *echo_off = "ATE0\r\n";
    unsigned char u;
    while (uart_ready()) {
        u = uart_read();
        putchar(u);
    }

    while (*echo_off) {
        uart_send(*echo_off);
        echo_off++;
    }

    while (uart_ready()) {
        u = uart_read();
        putchar(u);
    }
}

#define DEJITTER 5

int main(int argc, char **argv)
{
    char key_pressed = 0, echo_on = 1;
    int dejitter = DEJITTER;
    unsigned char c, u;
    zx_cls(PAPER_WHITE);
    printf("Dumb UART terminal\n");

    uart_init();
    putchar('>');
    while (1) {
        if (!key_pressed) {
            while (uart_ready()) {
                u = uart_read();
                if (u != 13 && u != 10 && (u < 32 || u > 128))
                    continue;
                putchar(u);
            }
            if (in_test_key()) {
                c = in_inkey();
                if (!c) {
                    key_pressed = 0;
                    continue;
                }
                key_pressed = 1;
                dejitter = DEJITTER;
                if (c != 13 && (c < 32 || c > 128))
                    continue;
                if (c == '!') {
                    echo_on = !echo_on;
                    printf("Echo is %s\n", echo_on ? "on" : "off");
                    continue;
                }
                uart_send(c);
                if (echo_on)
                    putchar(c);
                if (c == 13) {
                    uart_send(10);
                    if (echo_on)
                        putchar(10);
                }
            }
        } else {
            if (!in_test_key() || !in_inkey()) {
                if (dejitter) {
                    dejitter--;
                } else {
                    key_pressed = 0;
                }
            }
        }
    }

    return 0;
}

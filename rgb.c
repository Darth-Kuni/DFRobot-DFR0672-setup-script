#include <stdio.h>
#include <stdlib.h>
// ??wiringPi/I2C?
#include <wiringPi.h>
#include <wiringPiI2C.h>

#define Max_LED 3

int fd_i2c;
void setRGB(int num, int R, int G, int B);
void closeRGB();

static int clamp8(int v)
{
    if (v < 0) return 0;
    if (v > 255) return 255;
    return v;
}

int main(int argc, char *argv[])
{
    int r = 0;
    int g = 255;
    int b = 0;

    if (argc == 4)
    {
        r = clamp8(atoi(argv[1]));
        g = clamp8(atoi(argv[2]));
        b = clamp8(atoi(argv[3]));
    }
    else if (argc != 1)
    {
        fprintf(stderr, "Usage: %s [R G B]\n", argv[0]);
        fprintf(stderr, "Defaulting to green (0,255,0)\n");
    }

    // ??I2C????
    wiringPiSetup();
    fd_i2c = wiringPiI2CSetup(0x0d);
    if (fd_i2c < 0)
    {
        fprintf(stderr, "fail to init I2C\n");
        return -1;
    }

    closeRGB();
    delay(1);
    setRGB(Max_LED, r, g, b);

    return 0;
}

// ??RGB?,num??????Max_LED(3),????????
void setRGB(int num, int R, int G, int B)
{
    if (num >= Max_LED)
    {
        wiringPiI2CWriteReg8(fd_i2c, 0x00, 0xff);
        wiringPiI2CWriteReg8(fd_i2c, 0x01, R);
        wiringPiI2CWriteReg8(fd_i2c, 0x02, G);
        wiringPiI2CWriteReg8(fd_i2c, 0x03, B);
    }
    else if (num >= 0)
    {
        wiringPiI2CWriteReg8(fd_i2c, 0x00, num);
        wiringPiI2CWriteReg8(fd_i2c, 0x01, R);
        wiringPiI2CWriteReg8(fd_i2c, 0x02, G);
        wiringPiI2CWriteReg8(fd_i2c, 0x03, B);
    }
}

// ??RGB
void closeRGB()
{
    wiringPiI2CWriteReg8(fd_i2c, 0x07, 0x00);
}
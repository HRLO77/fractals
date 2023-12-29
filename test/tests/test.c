#include <stdio.h>
#include <math.h>
#define printf __mingw_printf
#define uint64 unsigned long
static inline double gcd(double n1, double n2){
    double gcd=1;
    double min = n1*0.5;
    unsigned long long int i;
    if (n2 < n1){
        min = n2*0.5;
    }
    for(i=2; i <= min; ++i){
        // Checks if i is factor of both integers
        if(fmod(n1,i)==0){
            if (fmod(n2,i)==0){
                gcd = i;
            }
        }
    }
    return 1/gcd;
}
int main(int argc, char* argv[]){ 
    printf("%f",gcd(36, 32));
    return 0;
}
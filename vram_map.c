#include <stdio.h>
#include <stdint.h>

#define ROW_WIDTH 160
#define X_OFFSET 32

int main(int argc, char **argv) {
   FILE *ofp;
   uint8_t odata[2];
   int x,y;
   int address;

   ofp = fopen("VRAMMAP.BIN", "wb");
   odata[0] = 0;
   odata[1] = 0;
   fwrite(odata,1,2,ofp);

   for (x = 0; x < 256; x++) {
      for (y = 0; y < 256; y++) {
         address = (x+X_OFFSET)/2 + y * ROW_WIDTH;
         odata[0] = (uint8_t) (address & 0xFF);
         odata[1] = (uint8_t) ((address & 0xFF00) >> 8);
         fwrite(odata,1,2,ofp);
      }
   }

   fclose (ofp);
   return 0;
}

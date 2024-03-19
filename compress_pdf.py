from ironpdf import *
import os
print('\033[38;2;0;0;255m Welcome to pdf compressor!\033[0m \n')
file = input("Enter the name of the pdf file you want to compress: ")
if not file.endswith('.pdf'):
    file = file+'.pdf'
    
if not (os.path.isfile(file)):
    print(f'\033[38;2;255;0;0m {file} does not exist\033[0m ')
    input("(Press enter to exit PDF compressor): ")
    
pdf = PdfDocument(file)
# Quality parameter can be 1-100, where 100 is 100% of original qualitys
level = int(input("Enter the %% of compression you want (1%%-99%%): "))%100
level = 100-level

pdf.CompressImages(level, input("Scale as well? (may cause distortion) (Y/n): ")=='Y')
f = f"COMPRESSED_{file[:-4]}.pdf"
pdf.SaveAs(f)
print(f"Saved {file} as {f}!")
input('(Press enter to exist PDF compressor): ')
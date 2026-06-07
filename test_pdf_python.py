import PyPDF2
import sys

def extract_pdf_text(pdf_path):
    try:
        with open(pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            print(f"Number of pages: {len(pdf_reader.pages)}\n")
            
            for page_num in range(len(pdf_reader.pages)):
                page = pdf_reader.pages[page_num]
                text = page.extract_text()
                print(f"=== PAGE {page_num + 1} ===")
                print(text)
                print("\n" + "="*50 + "\n")
                
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    pdf_path = r"e:\list_of_songs\4th Jan 26_Sunday Songs.pdf"
    extract_pdf_text(pdf_path)

# Multimodal OCR Strategy
## Objective
- Enable fast entry by scanning invoice images.
- Use Gemini 2.5 Flash Vision for high-accuracy text extraction.

## Pipeline
1. Flutter App: Convert image to Base64.
2. n8n: Decode Base64 and send to Gemini Vision Node.
3. Gemini: Extract 'Total Amount' and 'Store Name'.
4. Result: Automatically trigger the insertion workflow.

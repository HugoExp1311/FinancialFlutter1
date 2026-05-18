# AI Agent Workflow Logic
## Orchestration (n8n)
- Webhook receives user input from Flutter app.
- Router Agent analyzes intent (Insertion vs Analysis).
- Tool Calling mechanism:
  1. Ghi_Chep_Thu_Chi: Extracts entities and saves to Supabase.
  2. Phan_Tich_Tai_Chinh: Fetches history and provides personalized advice.

## Prompt Engineering
- System Message ensures mathematical accuracy (VND to USD conversion).
- Prevents hallucination by relying on SQL-based RAG.

import json

def build():
    with open("My workflow11.json", "r", encoding="utf-8") as f:
        data = json.load(f)

    webhook_node = next(n for n in data["nodes"] if n["name"] == "Webhook")
    supabase_node = next(n for n in data["nodes"] if n["name"] == "Insert to Supabase")
    groq_node = next(n for n in data["nodes"] if n["name"] == "Groq Chat Model")

    # Clone groq model for supervisor and analyst
    supervisor_groq = dict(groq_node)
    supervisor_groq["id"] = "supervisor-groq-id"
    supervisor_groq["name"] = "Supervisor Groq"
    supervisor_groq["position"] = [1000, 300]

    analyst_groq = dict(groq_node)
    analyst_groq["id"] = "analyst-groq-id"
    analyst_groq["name"] = "Analyst Groq"
    analyst_groq["position"] = [2000, 600]
    
    clerk_groq = dict(groq_node)
    clerk_groq["position"] = [2000, 100]

    # Create new nodes
    nodes = []
    
    # 1. Webhook
    webhook_node["position"] = [300, 300]
    nodes.append(webhook_node)

    # 2. Supervisor Chain
    supervisor_chain = {
        "parameters": {
            "promptType": "define",
            "text": "={{ $json.body.message }}",
            "hasOutputParser": True,
            "systemMessage": "Bạn là Quản Đốc (Supervisor) của ứng dụng Tài chính. Nhiệm vụ duy nhất của bạn là phân loại ý đồ của tin nhắn người dùng:\n- Nếu tin nhắn ra lệnh ghi chép mua sắm, nhận tiền, đổ xăng, đóng tiền điện (vd: 'Tôi vừa ăn phở 50k', 'Nhận lương 10tr') -> CHỌN 'insert'.\n- Nếu tin nhắn yêu cầu phân tích, hỏi đáp, dự đoán, xin lời khuyên tài chính, hoặc tính tổng (vd: 'Tháng này tiêu bao nhiêu', 'Làm sao để tiết kiệm', 'Phân tích chi tiêu') -> CHỌN 'analyze'.\n- Nếu là câu chào (vd 'hello', 'chào') -> CHỌN 'analyze'."
        },
        "type": "@n8n/n8n-nodes-langchain.chainLlm",
        "typeVersion": 1.4,
        "position": [700, 300],
        "id": "supervisor-chain-id",
        "name": "Supervisor Router"
    }
    nodes.append(supervisor_chain)

    # 3. Supervisor Parser
    supervisor_parser = {
        "parameters": {
            "schemaType": "manual",
            "inputSchema": "{\"type\":\"object\",\"properties\":{\"route\":{\"type\":\"string\",\"enum\":[\"insert\",\"analyze\"],\"description\":\"Luồng tiếp theo để xử lý\"}},\"required\":[\"route\"]}"
        },
        "type": "@n8n/n8n-nodes-langchain.outputParserStructured",
        "typeVersion": 1.3,
        "position": [700, 450],
        "id": "supervisor-parser-id",
        "name": "Router Parser"
    }
    nodes.append(supervisor_parser)
    nodes.append(supervisor_groq)

    # 4. IF / Switch Node
    switch_node = {
        "parameters": {
            "conditions": {
                "options": {
                    "caseSensitive": True,
                    "leftValue": "",
                    "typeValidation": "strict"
                },
                "conditions": [
                    {
                        "id": "c1",
                        "leftValue": "={{ $json.output.route }}",
                        "rightValue": "insert",
                        "operator": {
                            "type": "string",
                            "operation": "equals",
                            "name": "filter.operator.equals"
                        }
                    },
                    {
                        "id": "c2",
                        "leftValue": "={{ $json.output.route }}",
                        "rightValue": "analyze",
                        "operator": {
                            "type": "string",
                            "operation": "equals",
                            "name": "filter.operator.equals"
                        }
                    }
                ],
                "combinator": "and"
            },
            "options": {}
        },
        "type": "n8n-nodes-base.switch",
        "typeVersion": 3.1,
        "position": [1000, 300],
        "id": "switch-id",
        "name": "Switch Router"
    }
    nodes.append(switch_node)

    # 5. Clerk Agent (For Insert)
    clerk_chain = {
        "parameters": {
            "promptType": "define",
            "text": "={{ $('Webhook').item.json.body.message }}",
            "hasOutputParser": True,
            "systemMessage": "Bạn là Thư ký Nhập liệu (Data Clerk). Hãy bóc tách giao dịch từ tin nhắn. Không cần quan tâm tới phân tích. Chỉ trả về JSON."
        },
        "type": "@n8n/n8n-nodes-langchain.chainLlm",
        "typeVersion": 1.4,
        "position": [1400, 100],
        "id": "clerk-chain-id",
        "name": "Data Clerk"
    }
    clerk_parser = next(n for n in data["nodes"] if n["name"] == "Structured Output Parser")
    clerk_parser["position"] = [1400, 250]
    nodes.append(clerk_chain)
    nodes.append(clerk_parser)
    nodes.append(clerk_groq)

    # 6. Prepare Payload & Insert Supabase (For Insert)
    prep_payload = next(n for n in data["nodes"] if n["name"] == "Prepare Payload")
    prep_payload["position"] = [1700, 100]
    supabase_node["position"] = [2000, 100]
    nodes.append(prep_payload)
    nodes.append(supabase_node)

    respond_insert = {
        "parameters": {
            "respondWith": "json",
            "responseBody": "={\n  \"replyMessage\": \"{{ $('Prepare Payload').item.json.replyMessage }}\"\n}\n",
            "options": {"responseCode": 200}
        },
        "type": "n8n-nodes-base.respondToWebhook",
        "typeVersion": 1.5,
        "position": [2300, 100],
        "id": "respond-insert-id",
        "name": "Respond Webhook (Inserted)"
    }
    nodes.append(respond_insert)

    # 7. Analyst Agent (For Analyze)
    analyst_chain = {
        "parameters": {
            "promptType": "define",
            "text": "Dữ liệu 100 giao dịch:\n{{ $('Webhook').item.json.body.history }}\n\nCâu hỏi/Yêu cầu: {{ $('Webhook').item.json.body.message }}",
            "hasOutputParser": False,
            "systemMessage": "Bạn là Chuyên gia Tài chính cấp cao (Senior Financial Analyst). Nhiệm vụ của bạn là đọc Dữ liệu lịch sử (100 giao dịch gần nhất) và Phân tích, cho lời khuyên, tính tổng số tiền hoặc trả lời câu hỏi của người dùng.\nHãy sử dụng giọng điệu chuyên nghiệp, markdown gọn gàng. Cắt giảm chi tiêu nếu cần thiết."
        },
        "type": "@n8n/n8n-nodes-langchain.chainLlm",
        "typeVersion": 1.4,
        "position": [1400, 500],
        "id": "analyst-chain-id",
        "name": "Financial Analyst"
    }
    nodes.append(analyst_chain)
    nodes.append(analyst_groq)

    respond_analyze = {
        "parameters": {
            "respondWith": "json",
            "responseBody": "={\n  \"replyMessage\": \"{{ $json.text }}\"\n}\n",
            "options": {"responseCode": 200}
        },
        "type": "n8n-nodes-base.respondToWebhook",
        "typeVersion": 1.5,
        "position": [1800, 500],
        "id": "respond-analyze-id",
        "name": "Respond Webhook (Analysis)"
    }
    nodes.append(respond_analyze)

    # CONNECTIONS
    connections = {
        "Webhook": {
            "main": [ [ {"node": "Supervisor Router", "type": "main", "index": 0} ] ]
        },
        "Supervisor Groq": {
            "ai_languageModel": [ [ {"node": "Supervisor Router", "type": "ai_languageModel", "index": 0} ] ]
        },
        "Router Parser": {
            "ai_outputParser": [ [ {"node": "Supervisor Router", "type": "ai_outputParser", "index": 0} ] ]
        },
        "Supervisor Router": {
            "main": [ [ {"node": "Switch Router", "type": "main", "index": 0} ] ]
        },
        "Switch Router": {
            "main": [
                [ {"node": "Data Clerk", "type": "main", "index": 0} ],    # output 0: insert
                [ {"node": "Financial Analyst", "type": "main", "index": 0} ]     # output 1: analyze
            ]
        },
        "Groq Chat Model": {
            "ai_languageModel": [ [ {"node": "Data Clerk", "type": "ai_languageModel", "index": 0} ] ]
        },
        "Structured Output Parser": {
            "ai_outputParser": [ [ {"node": "Data Clerk", "type": "ai_outputParser", "index": 0} ] ]
        },
        "Data Clerk": {
            "main": [ [ {"node": "Prepare Payload", "type": "main", "index": 0} ] ]
        },
        "Prepare Payload": {
            "main": [ [ {"node": "Insert to Supabase", "type": "main", "index": 0} ] ]
        },
        "Insert to Supabase": {
            "main": [ [ {"node": "Respond Webhook (Inserted)", "type": "main", "index": 0} ] ]
        },
        "Analyst Groq": {
            "ai_languageModel": [ [ {"node": "Financial Analyst", "type": "ai_languageModel", "index": 0} ] ]
        },
        "Financial Analyst": {
            "main": [ [ {"node": "Respond Webhook (Analysis)", "type": "main", "index": 0} ] ]
        }
    }

    data["nodes"] = nodes
    data["connections"] = connections

    with open("My workflow11_MultiAgent.json", "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        
build()

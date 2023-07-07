#!/data/data/com.termux/files/usr/bin/python
import textwrap
from flask import Flask, request
from revChatGPT.V1 import Chatbot,configure
from flask_cors import CORS


"""
update ~/.config/revChatGPT/config.json
```
mkdir -p ~/.config/revChatGPT
vim ~/.config/revChatGPT/config.json
```
{
"email": "email",
"password": "your password"
}
"""
app = Flask(__name__)
CORS(app)

chatbot = Chatbot(config=configure())
prompts = {
        "ask": """
        If my input question is in Chinese, translate my question into English and answer the translated question;
        and if my input question is in English, fix the grammar/spelling errors and answer the fixed question

        Your output format:
        **Translate**(optional): <transated input>
        **Fixed**(optional): <grammer/spelling error fixed input>
        **Answer**: <your answer>

        Here is my input question:

        """,
        "english": """
        You are a linguistics expert, and I am a fourth-year student from a university in China. I will engage in conversation with you, and you will provide corresponding responses based on the language I input:

        1. If my input is in Chinese, please translate it into colloquial English.
        2. If my input is not in Chinese, please first determine if there are any grammar errors. If there are, please point them out. If there are no grammar errors, please translate the input into Chinese and then list difficult words, phrases, and grammar based on my language proficiency.

        Your reply will be in the following format. If there are no grammar errors or difficult sentences, you will not show these parts:
        **Grammar**(optional): <grammar fixed input>
        **Translate**(optional): <translated input>
        **Learn**(optional):
        1. <difficult words>
        2. <difficult sentence>
        3. <and so on>

        Here is my input:

        """
        }

@app.route('/<op>', methods=["GET", "POST"])
def ask(op):
    question = request.values.get('q')
    #print("get", op, question, request.values)
    if not question:
        return {}
    response = {}
    prompt = textwrap.dedent(prompts.get(op,""))
    for data in chatbot.ask(prompt + question):
        response["answer"] = data["message"]

    #print("result", response)
    return response


if __name__ == '__main__':
    app.run()

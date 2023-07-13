#!/data/data/com.termux/files/usr/bin/python
import re
import textwrap

from flask import Flask, request
from flask_cors import CORS
from revChatGPT.V1 import Chatbot, configure

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


def init_chatbot(prompt=""):
    chatbot = Chatbot(config=configure())
    for data in chatbot.ask(prompt):
        # print("init", data["message"])
        pass
    return chatbot


en_init = """
You will translate my non-English input into English, rephrase my English input to make it more accurate and natural, and you will first show the translated/corrected English input and then respond to my questions in English.
Your output format should be:

**Rephrased**: <Translated/Rephrased input>
**Answer**: <Your English answer>

Now, here’s my first question: "你好"
"""

ch_init = """
You will translate my non-English input into English, rephrase my English input to make it more accurate and natural, and then you will respond to my questions in Chinese.
Now, here’s my first question: "Hello"
"""
en_gpt = init_chatbot(en_init)
ch_gpt = init_chatbot(ch_init)

gpts = {"ask": en_gpt, "english": en_gpt, "voice": ch_gpt}

pattern = r"\*\*Answer\*\*:\s*(.*)"


@app.route("/<op>", methods=["GET", "POST"])
def ask(op):
    question = request.values.get("q")
    # print("get", op, question, request.values)
    if not question:
        return {}
    response = {}
    gpt = gpts.get(op, "ask")
    for data in gpt.ask(question):
        response["answer"] = data["message"]
        # match = re.search(pattern, data["message"])
        # if match:
        #     extracted_content = match.group(1)
        #     response["ans"] = extracted_content

    # print("result", response)
    return response


if __name__ == "__main__":
    app.run()

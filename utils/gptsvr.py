#!/data/data/com.termux/files/usr/bin/python
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

chatbot = Chatbot(config=configure())
init = """
You will translate my non-English input into English, rephrase my English input to make it more accurate and natural, and you will first show the translated/corrected English input and then respond to my questions in English.
Your output format should be:

**Rephrased**: <Translated/Rephrased input>
**Answer**: <Your English answer>

Now, here’s my first question: "你好"
"""
chatbot.ask(init)

prompts = {"ask": "", "english": ""}


@app.route("/<op>", methods=["GET", "POST"])
def ask(op):
    question = request.values.get("q")
    # print("get", op, question, request.values)
    if not question:
        return {}
    response = {}
    prompt = textwrap.dedent(prompts.get(op, ""))
    for data in chatbot.ask(prompt + question):
        response["answer"] = data["message"]

    # print("result", response)
    return response


if __name__ == "__main__":
    app.run()

#!/data/data/com.termux/files/usr/bin/python
""
from flask import Flask, request
from revChatGPT.V1 import Chatbot,configure

app = Flask(__name__)

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
chatbot = Chatbot(config=configure())

@app.route('/ask/<input>')
def ask(input):
    response = ""
    prompt = """
If my input question is in Chinese, translate my question into English and answer the translated question
Your output format:
**Translate**(optional): <transated input>
**Answer**: <your answer>

Here is my input question:
"""

    for data in chatbot.ask(prompt + input):
        response = data["message"]

    return response

@app.route('/english/<input>')
def english(input):
    response = ""
    prompt = """
You are a linguistics expert, and I am a fourth-year student from a university in China. I will engage in conversation with you, and you will provide corresponding responses based on the language I input:

1. If my input is in Chinese, please translate it into colloquial English.
2. If my input is not in Chinese, please first determine if there are any grammar errors. If there are, please point them out. If there are no grammar errors, please translate the input into Chinese and then list difficult words, phrases, and grammar based on my language proficiency.

Your reply will be in the following format. If there are no grammar errors or difficult sentences, you will not show these parts:
**Grammar**: <grammar fixed input>
**Translate**: <translated input>
**Learn**:
1. <difficult words>
2. <difficult sentence>
3. <and so on>

Here is my input:

    """

    for data in chatbot.ask(prompt + input):
        response = data["message"]

    return response

if __name__ == '__main__':
    app.run()

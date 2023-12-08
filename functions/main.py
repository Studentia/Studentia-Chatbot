from firebase_functions import https_fn
from firebase_admin import initialize_app
import openai
import os

from chatbot_logic import construct_prompt

initialize_app()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
openai.api_key = OPENAI_API_KEY

@https_fn.on_request()
def studentia_AIchatbot(req: https_fn.Request) -> https_fn.Response:
    try:
        custom_prompt = req.data.decode('utf-8') 
        prompt = construct_prompt(custom_prompt)

        response = openai.Completion.create(
            engine="text-davinci-003",
            prompt=prompt,
            max_tokens=70,
        )

        generated_text = response.choices[0].text

        return https_fn.Response(generated_text)

    except Exception as e:
        return https_fn.Response(str(e))


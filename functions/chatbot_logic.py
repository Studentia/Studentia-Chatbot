import pandas as pd
import numpy as np
import openai
import os
from typing import List, Tuple, Dict
from transformers import GPT2TokenizerFast

df = pd.read_csv("chatbot/ewha_database.csv")
doc_embeddings = pd.read_csv("chatbot/document_embeddings.csv")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
openai.api_key = OPENAI_API_KEY

MAX_SECTION_LEN = 300
SEPARATOR = "\n* "

tokenizer = GPT2TokenizerFast.from_pretrained("gpt2")
separator_len = len(tokenizer.tokenize(SEPARATOR))

def get_embedding(text: str) -> List[float]:
    result = openai.Embedding.create(
        model="text-search-curie-query-001",
        input=text
    )
    return result["data"][0]["embedding"]

def get_query_embedding(text: str) -> List[float]:
    return get_embedding(text)

def load_embeddings() -> Dict[Tuple[str, str], List[float]]:
    max_dim = max([int(c) for c in doc_embeddings.columns if c != "title" and c != "heading"])
    return {
           (r.title, r.heading): [r[str(i)] for i in range(max_dim + 1)] for _, r in doc_embeddings.iterrows()
    }

document_embeddings = load_embeddings()

def vector_similarity(x: List[float], y: List[float]) -> float:
    return np.dot(np.array(x), np.array(y))

def order_document_sections_by_query_similarity(query: str, contexts: Dict[Tuple[str, str], np.array]) -> List[Tuple[float, Tuple[str, str]]]:
    query_embedding = get_query_embedding(query)
    
    document_similarities = sorted([
        (vector_similarity(query_embedding, doc_embedding), doc_index) for doc_index, doc_embedding in contexts.items()
    ], reverse=True)
    
    return document_similarities

def construct_prompt(question: str) -> str:
    most_relevant_document_sections = order_document_sections_by_query_similarity(question, document_embeddings)
    
    chosen_sections = []
    chosen_sections_len = 0
    chosen_sections_indexes = []
     
    for _, section_index in most_relevant_document_sections:
        title, heading = section_index
        document_section = df[(df["title"] == title) & (df["heading"] == heading)].iloc[0]
        
        chosen_sections_len += document_section.token + separator_len
        if chosen_sections_len > MAX_SECTION_LEN:
            break
            
        chosen_sections.append(SEPARATOR + document_section.content.replace("\n", " "))
        chosen_sections_indexes.append(str(section_index))
    
    header = """Answer the question as truthfully as possible using the provided context, and if the answer is not undoubtedly contained within the text below, absolutely don't answer anything except for saying "Sorry, I don't have that information. Please visit Ewha Womans University official website at https://www.ewha.ac.kr/ewhaen/index.do for more information."\n\nContext:\n"""
    
    return header + "".join(chosen_sections) + "\n\n Q: " + question + "\n A:"



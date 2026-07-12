from collections import Counter
from math import log2

def normolize(string: str) -> list:
    return [word for word in string.split(" ") if len(word) >= 8]

def shannon_entropy(data: bytes) -> float:
    """Возвращает эмпирическую энтропию в битах на байт."""
    if not data:
        return 0.0

    length = len(data)
    counts = Counter(data)

    return abs(-sum(
        (count / length) * log2(count / length)
        for count in counts.values()
    ))

""" 
normal=normolize("1234 short_word very_long_word_123")
for word in normal:
    
    word_bytes = word.encode('utf-8')
    
    entropy = shannon_entropy(word_bytes)
    print(f"Энтропия для '{word}': {entropy:.2f}")
"""
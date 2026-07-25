import sys

def check_braces(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    lines = content.split('\n')
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char in '{[(':
                stack.append((char, i+1, j+1))
            elif char in '}])':
                if not stack:
                    print(f"Unmatched {char} at line {i+1}")
                    return
                top, line_num, col_num = stack.pop()
                expected = {'{': '}', '[': ']', '(': ')'}[top]
                if char != expected:
                    print(f"Mismatched {char} at line {i+1}, expected {expected} to match {top} at line {line_num}")
                    return
    if stack:
        print("Unclosed braces:")
        for char, line_num, col_num in stack:
            print(f"  {char} at line {line_num}:{col_num}")
    else:
        print("All braces match perfectly.")

check_braces(sys.argv[1])

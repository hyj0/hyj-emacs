
def get_display_content(self):
    # ��ȡ��ǰ���Ļ�������򻺳�����
    current_screen = self.screen
    # ������ȡ�ı�����
    lines = []
    for row in range(current_screen.lines):
        line_str = ""
        for col in range(current_screen.columns):
            # ��ȡ��Ԫ���ַ�������cell���ݽṹΪ[char, style]��
            cell = current_screen.buffer[row][col]
            line_str += cell.data if cell else " "
        lines.append(line_str.rstrip())
    return "\n".join(lines)
def get_cursor_position(self):
    return (self.screen.row, self.screen.col)  # ����ʵ������������

# cursor
x = self.buffer_widget.backend.screen.cursor.x #��
y = self.buffer_widget.backend.screen.cursor.y #��
print (x, y)

#content
content = get_display_content (self.buffer_widget.backend)

data = [x, y, content]
set_emacs_var ('*my-eaf-term-screen-data*',  data)


print (data)

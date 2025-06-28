
def get_display_content(self):
    # 获取当前活动屏幕（主屏或缓冲屏）
    current_screen = self.screen
    # 逐行提取文本内容
    lines = []
    for row in range(current_screen.lines):
        line_str = ""
        for col in range(current_screen.columns):
            # 获取单元格字符（假设cell数据结构为[char, style]）
            cell = current_screen.buffer[row][col]
            line_str += cell.data if cell else " "
        lines.append(line_str.rstrip())
    return "\n".join(lines)
def get_cursor_position(self):
    return (self.screen.row, self.screen.col)  # 根据实际属性名调整

# cursor
x = self.buffer_widget.backend.screen.cursor.x #行
y = self.buffer_widget.backend.screen.cursor.y #列
print (x, y)

#content
content = get_display_content (self.buffer_widget.backend)

data = [x, y, content]
set_emacs_var ('*my-eaf-term-screen-data*',  data)


print (data)

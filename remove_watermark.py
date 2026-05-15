"""
去除PDF水印：移除每页重复的"学科网（北京）股份有限公司"文字水印
"""
import fitz  # PyMuPDF
import re
from io import BytesIO

INPUT = "/root/.openclaw/media/inbound/2026年广州大学附属中学中考数学模拟试题---6112db44-8052-4002-b8a2-0a228476240f.pdf"
OUTPUT = "/root/.openclaw/media/outbound/2026年广州大学附属中学中考数学模拟试题-无水印.pdf"

WATERMARK_TEXT = "学科网（北京）股份有限公司"

def remove_watermark_from_page(page):
    """逐页检测并移除水印文字"""
    # 获取页面上所有文本块
    blocks = page.get_text("blocks")
    original_text = page.get_text()
    
    # 检查是否包含水印文字
    if WATERMARK_TEXT not in original_text:
        return False
    
    # 记录需要移除的文本块
    watermark_blocks = []
    for block in blocks:
        x0, y0, x1, y1, text, block_no, block_type = block
        if WATERMARK_TEXT in text:
            watermark_blocks.append(block)
    
    if not watermark_blocks:
        return False
    
    print(f"  第 {page.number + 1} 页: 发现 {len(watermark_blocks)} 个水印文本块")
    
    # 方法：使用 redact 移除水印区域
    for block in watermark_blocks:
        x0, y0, x1, y1, text, block_no, block_type = block
        # 稍微扩大区域确保完全覆盖
        padding = 2
        rect = fitz.Rect(x0 - padding, y0 - padding, x1 + padding, y1 + padding)
        # 用白色填充（覆盖水印）
        page.add_redact_annot(rect, fill=(1, 1, 1))
    
    page.apply_redactions()
    return True

def main():
    print(f"读取PDF: {INPUT}")
    doc = fitz.open(INPUT)
    print(f"共 {len(doc)} 页\n")
    
    total_removed = 0
    for page_num in range(len(doc)):
        page = doc[page_num]
        if remove_watermark_from_page(page):
            total_removed += 1
    
    print(f"\n共处理 {total_removed} 页的水印")
    
    doc.save(OUTPUT)
    print(f"已保存到: {OUTPUT}")
    doc.close()

if __name__ == "__main__":
    main()

"""
彻底去除PDF水印：对准水印位置进行白色覆盖
"""
import fitz

INPUT = "/root/.openclaw/media/inbound/2026年广州大学附属中学中考数学模拟试题---6112db44-8052-4002-b8a2-0a228476240f.pdf"
OUTPUT = "/root/.openclaw/media/outbound/2026年广州大学附属中学中考数学模拟试题-无水印.pdf"

WATERMARK_TEXT = "学科网（北京）股份有限公司"

def remove_watermarks():
    doc = fitz.open(INPUT)
    print(f"共 {len(doc)} 页\n")
    
    for page_num in range(len(doc)):
        page = doc[page_num]
        d = page.get_text('dict', flags=fitz.TEXT_PRESERVE_WHITESPACE)
        
        found = False
        for block in d['blocks']:
            if block['type'] != 0:
                continue
            for line in block['lines']:
                for span in line['spans']:
                    t = span.get('text', '').strip()
                    if WATERMARK_TEXT in t:
                        bbox = span['bbox']
                        # 扩大覆盖区域
                        pad = 5
                        x0 = max(0, bbox[0] - pad)
                        y0 = max(0, bbox[1] - pad)
                        x1 = min(page.rect.width, bbox[2] + pad)
                        y1 = min(page.rect.height, bbox[3] + pad)
                        
                        rect = fitz.Rect(x0, y0, x1, y1)
                        page.add_redact_annot(rect, fill=(1, 1, 1))
                        print(f"  第{page_num+1}页: 覆盖区域 {rect}, 原文本=\"{t}\"")
                        found = True
        
        # 同时检查并覆盖页面底部可能的水印区域（底部中间横条）
        page_h = page.rect.height
        page_w = page.rect.width
        
        # 覆盖整页底部的水印条（底部中心区域）
        # 水印文字出现在底部附近
        bottom_rect = fitz.Rect(0, page_h - 30, page_w, page_h)
        page.add_redact_annot(bottom_rect, fill=(1, 1, 1))
        
        if found:
            print(f"  第{page_num+1}页: 额外覆盖底部整条水印区")
        else:
            # 检查是否还有水印文本
            full_text = page.get_text()
            if WATERMARK_TEXT in full_text:
                print(f"  第{page_num+1}页: 发现水印但位置未定位到")
                # 尝试模糊匹配
                for block in d['blocks']:
                    if block['type'] != 0:
                        continue
                    for line in block['lines']:
                        for span in line['spans']:
                            t = span.get('text', '').strip()
                            if len(t) > 0:
                                bbox = span['bbox']
                                if bbox[1] > page_h * 0.85:  # 在底部85%以下的区域
                                    pad = 3
                                    rect = fitz.Rect(bbox[0]-pad, bbox[1]-pad, bbox[2]+pad, bbox[3]+pad)
                                    page.add_redact_annot(rect, fill=(1, 1, 1))
        
        page.apply_redactions()
    
    doc.save(OUTPUT)
    print(f"\n已保存到: {OUTPUT}")
    doc.close()

if __name__ == "__main__":
    remove_watermarks()
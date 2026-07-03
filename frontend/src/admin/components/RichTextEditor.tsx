import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Link from '@tiptap/extension-link';
import Image from '@tiptap/extension-image';
import Placeholder from '@tiptap/extension-placeholder';
import DOMPurify from 'dompurify';
import { useEffect } from 'react';
import { useI18n } from '../i18n';

type Props = {
  value: string;
  onChange: (html: string) => void;
  placeholder?: string;
  minHeight?: number;
};

export function RichTextEditor({ value, onChange, placeholder, minHeight = 280 }: Props) {
  const { t } = useI18n();

  const editor = useEditor({
    extensions: [
      StarterKit,
      Link.configure({ openOnClick: false, HTMLAttributes: { rel: 'noopener noreferrer' } }),
      Image.configure({ HTMLAttributes: { class: 'editor-inline-image' } }),
      Placeholder.configure({ placeholder: placeholder ?? t('articles.fieldContentPlaceholder') }),
    ],
    content: value,
    onUpdate: ({ editor: ed }) => {
      onChange(DOMPurify.sanitize(ed.getHTML()));
    },
    editorProps: {
      attributes: {
        class: 'rich-editor-body tiptap-body',
        style: `min-height:${minHeight}px`,
      },
    },
  });

  useEffect(() => {
    if (!editor) return;
    const sanitized = DOMPurify.sanitize(value || '');
    if (sanitized !== editor.getHTML()) {
      editor.commands.setContent(sanitized, { emitUpdate: false });
    }
  }, [value, editor]);

  if (!editor) return null;

  const addLink = () => {
    const url = window.prompt(t('richText.link'), 'https://');
    if (!url) return;
    editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run();
  };

  const addImage = () => {
    const url = window.prompt(t('richText.image'), '');
    if (!url) return;
    editor.chain().focus().setImage({ src: url }).run();
  };

  return (
    <div className="rich-editor">
      <div className="rich-editor-toolbar" role="toolbar" aria-label={t('richText.toolbar')}>
        <button type="button" className={`rich-editor-btn${editor.isActive('bold') ? ' active' : ''}`} onClick={() => editor.chain().focus().toggleBold().run()}>B</button>
        <button type="button" className={`rich-editor-btn${editor.isActive('italic') ? ' active' : ''}`} onClick={() => editor.chain().focus().toggleItalic().run()}>I</button>
        <button type="button" className={`rich-editor-btn${editor.isActive('heading', { level: 2 }) ? ' active' : ''}`} onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}>H2</button>
        <button type="button" className={`rich-editor-btn${editor.isActive('bulletList') ? ' active' : ''}`} onClick={() => editor.chain().focus().toggleBulletList().run()}>•</button>
        <button type="button" className={`rich-editor-btn${editor.isActive('orderedList') ? ' active' : ''}`} onClick={() => editor.chain().focus().toggleOrderedList().run()}>1.</button>
        <button type="button" className="rich-editor-btn" onClick={addLink}>🔗</button>
        <button type="button" className="rich-editor-btn" onClick={addImage}>🖼</button>
      </div>
      <EditorContent editor={editor} />
    </div>
  );
}

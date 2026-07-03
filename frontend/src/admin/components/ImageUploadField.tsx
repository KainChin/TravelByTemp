import { useRef, useState } from 'react';
import { adminApi } from '../api';
import { useI18n } from '../i18n';

type Props = {
  label?: string;
  value: string;
  onChange: (url: string) => void;
};

export function ImageUploadField({ label, value, onChange }: Props) {
  const { t } = useI18n();
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const upload = async (file: File) => {
    setUploading(true);
    setError('');
    try {
      const url = await adminApi.uploadMedia(file);
      onChange(url);
    } catch (e) {
      setError(e instanceof Error ? e.message : t('upload.failed'));
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="image-upload-field">
      <span className="field-label">{label ?? t('upload.label')}</span>
      {value && <img src={value} alt="" className="editor-thumb-preview" />}
      <div className="image-upload-actions">
        <input
          ref={inputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif"
          className="sr-only"
          onChange={(e) => {
            const file = e.target.files?.[0];
            if (file) upload(file);
            e.target.value = '';
          }}
        />
        <button
          type="button"
          className="btn-secondary"
          disabled={uploading}
          onClick={() => inputRef.current?.click()}
        >
          {uploading ? t('upload.uploading') : t('upload.label')}
        </button>
        <input
          className="editor-input"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={t('upload.urlPlaceholder')}
        />
      </div>
      {error && <p className="field-error">{error}</p>}
    </div>
  );
}

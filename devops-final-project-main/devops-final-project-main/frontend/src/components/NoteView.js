import React from 'react';
import './NoteView.css';

function NoteView({ note, onEdit, onDelete }) {
  if (!note) {
    return null;
  }

  return (
    <div className="note-view">
      <div className="note-view-header">
        <h2>{note.title || 'Untitled Note'}</h2>
        <div className="note-view-actions">
          <button className="btn btn-secondary" onClick={onEdit}>
            Edit
          </button>
          <button className="btn btn-danger" onClick={onDelete}>
            Delete
          </button>
        </div>
      </div>

      <div className="note-view-meta">
        <span>
          Created: {new Date(note.createdAt || note.timestamp).toLocaleString()}
        </span>
        {note.updatedAt && note.updatedAt !== note.createdAt && (
          <span>
            Updated: {new Date(note.updatedAt).toLocaleString()}
          </span>
        )}
      </div>

      <div className="note-view-content">
        {note.content ? (
          <p style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
            {note.content}
          </p>
        ) : (
          <p className="empty-content">No content</p>
        )}
      </div>
    </div>
  );
}

export default NoteView;


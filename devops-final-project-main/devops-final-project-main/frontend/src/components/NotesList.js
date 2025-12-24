import React from 'react';
import './NotesList.css';

function NotesList({ notes, selectedNote, onSelectNote, onEditNote, onDeleteNote }) {
  if (notes.length === 0) {
    return (
      <div className="notes-list-empty">
        <p>No notes yet. Create your first note!</p>
      </div>
    );
  }

  return (
    <div className="notes-list">
      <h3>Your Notes ({notes.length})</h3>
      <div className="notes-items">
        {notes.map(note => (
          <div
            key={note.id}
            className={`note-item ${selectedNote?.id === note.id ? 'active' : ''}`}
            onClick={() => onSelectNote(note)}
          >
            <div className="note-item-header">
              <h4>{note.title || 'Untitled'}</h4>
              <div className="note-item-actions">
                <button
                  className="btn-icon"
                  onClick={(e) => {
                    e.stopPropagation();
                    onEditNote(note);
                  }}
                  title="Edit"
                >
                  ✏️
                </button>
                <button
                  className="btn-icon"
                  onClick={(e) => {
                    e.stopPropagation();
                    onDeleteNote(note.id);
                  }}
                  title="Delete"
                >
                  🗑️
                </button>
              </div>
            </div>
            <p className="note-item-preview">
              {note.content?.substring(0, 100) || 'No content'}
              {note.content?.length > 100 ? '...' : ''}
            </p>
            <div className="note-item-meta">
              <span>{new Date(note.createdAt || note.timestamp).toLocaleDateString()}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default NotesList;


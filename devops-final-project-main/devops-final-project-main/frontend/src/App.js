import React, { useState, useEffect } from 'react';
import './App.css';
import NotesList from './components/NotesList';
import NoteForm from './components/NoteForm';
import NoteView from './components/NoteView';
import { getNotes, createNote, updateNote, deleteNote } from './services/api';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod';

function App() {
  const [notes, setNotes] = useState([]);
  const [selectedNote, setSelectedNote] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadNotes();
  }, []);

  const loadNotes = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await getNotes(API_BASE_URL);
      setNotes(data);
    } catch (err) {
      setError('Failed to load notes. Please check your API configuration.');
      console.error('Error loading notes:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateNote = async (noteData) => {
    try {
      const newNote = await createNote(API_BASE_URL, noteData);
      setNotes([...notes, newNote]);
      setIsEditing(false);
      setSelectedNote(null);
    } catch (err) {
      setError('Failed to create note');
      console.error('Error creating note:', err);
    }
  };

  const handleUpdateNote = async (id, noteData) => {
    try {
      const updatedNote = await updateNote(API_BASE_URL, id, noteData);
      setNotes(notes.map(note => note.id === id ? updatedNote : note));
      setIsEditing(false);
      setSelectedNote(updatedNote);
    } catch (err) {
      setError('Failed to update note');
      console.error('Error updating note:', err);
    }
  };

  const handleDeleteNote = async (id) => {
    if (window.confirm('Are you sure you want to delete this note?')) {
      try {
        await deleteNote(API_BASE_URL, id);
        setNotes(notes.filter(note => note.id !== id));
        if (selectedNote?.id === id) {
          setSelectedNote(null);
        }
      } catch (err) {
        setError('Failed to delete note');
        console.error('Error deleting note:', err);
      }
    }
  };

  const handleSelectNote = (note) => {
    setSelectedNote(note);
    setIsEditing(false);
  };

  const handleEditNote = (note) => {
    setSelectedNote(note);
    setIsEditing(true);
  };

  const handleNewNote = () => {
    setSelectedNote(null);
    setIsEditing(true);
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>📝 Cloud Notes</h1>
        <p>Serverless Notes Application</p>
      </header>

      {error && (
        <div className="error-banner">
          {error}
          <button onClick={() => setError(null)}>×</button>
        </div>
      )}

      <div className="container">
        <div className="sidebar">
          <button className="btn btn-primary" onClick={handleNewNote}>
            + New Note
          </button>
          {isLoading ? (
            <div className="loading">Loading notes...</div>
          ) : (
            <NotesList
              notes={notes}
              selectedNote={selectedNote}
              onSelectNote={handleSelectNote}
              onEditNote={handleEditNote}
              onDeleteNote={handleDeleteNote}
            />
          )}
        </div>

        <div className="main-content">
          {isEditing ? (
            <NoteForm
              note={selectedNote}
              onSubmit={selectedNote ? 
                (data) => handleUpdateNote(selectedNote.id, data) : 
                handleCreateNote
              }
              onCancel={() => {
                setIsEditing(false);
                setSelectedNote(null);
              }}
            />
          ) : selectedNote ? (
            <NoteView
              note={selectedNote}
              onEdit={() => handleEditNote(selectedNote)}
              onDelete={() => handleDeleteNote(selectedNote.id)}
            />
          ) : (
            <div className="empty-state">
              <h2>Welcome to Cloud Notes</h2>
              <p>Select a note from the sidebar or create a new one to get started.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;


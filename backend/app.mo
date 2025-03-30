import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Hash "mo:base/Hash";

actor NoteApp {
  // Define types
  public type NoteId = Nat;
  public type Note = {
    id: NoteId;
    title: Text;
    content: Text;
    createdAt: Time.Time;
    updatedAt: Time.Time;
  };

  // State variables
  private stable var nextNoteId : NoteId = 0;
  private stable var noteEntries : [(NoteId, Note)] = [];
  
  // Initialize HashMap from stable storage
  private var notes = HashMap.fromIter<NoteId, Note>(
    noteEntries.vals(), 
    10, 
    Nat.equal, 
    Hash.hash
  );

  // Create a new note
  public func createNote(title : Text, content : Text) : async NoteId {
    let timestamp = Time.now();
    let note : Note = {
      id = nextNoteId;
      title = title;
      content = content;
      createdAt = timestamp;
      updatedAt = timestamp;
    };

    notes.put(nextNoteId, note);
    nextNoteId += 1;
    
    return note.id;
  };

  // Get all notes
  public query func getAllNotes() : async [Note] {
    Iter.toArray(Iter.map(notes.vals(), func (note : Note) : Note { note }))
  };

  // Get a specific note by id
  public query func getNote(id : NoteId) : async ?Note {
    notes.get(id)
  };

  // Update a note
  public func updateNote(id : NoteId, title : Text, content : Text) : async Bool {
    switch (notes.get(id)) {
      case (null) {
        return false;
      };
      case (?existingNote) {
        let updatedNote : Note = {
          id = id;
          title = title;
          content = content;
          createdAt = existingNote.createdAt;
          updatedAt = Time.now();
        };
        notes.put(id, updatedNote);
        return true;
      };
    }
  };

  // Delete a note
  public func deleteNote(id : NoteId) : async Bool {
    switch (notes.get(id)) {
      case (null) { return false; };
      case (_) {
        notes.delete(id);
        return true;
      };
    }
  };

  // Search notes by title or content
  public query func searchNotes(msg : Text) : async [Note] {
    let searchQuery = Text.toLowercase(msg);
    let filterNotes = func (note : Note) : Bool {
      let titleLower = Text.toLowercase(note.title);
      let contentLower = Text.toLowercase(note.content);
      
      Text.contains(titleLower, #text searchQuery) or 
      Text.contains(contentLower, #text searchQuery)
    };
    
    Iter.toArray(
      Iter.filter(notes.vals(), filterNotes)
    )
  };

  // For persistence when upgrading
  system func preupgrade() {
    noteEntries := Iter.toArray(notes.entries());
  };

  system func postupgrade() {
    noteEntries := [];
  };
}
with Ada.Strings.Unbounded;
with Editor.State;

package Editor.Files is

   type File_Status is
     (Ok,
      Not_Found,
      Is_Directory,
      Permission_Denied,
      Invalid_Path,
      Decode_Error,
      Io_Error);


   type File_External_Change_Status is
     (File_External_Status_Unknown,
      File_External_Status_Unchanged,
      File_External_Status_Modified,
      File_External_Status_Missing,
      File_External_Status_Unreadable,
      File_External_Status_Replaced);

   --  Return a best-effort, non-persisted identity token label for an
   --  existing regular file.  The helper only reads file metadata and never
   --  opens, hashes, writes, or mutates the file.
   function Current_Token_Label
     (Path  : String;
      Found : out Boolean) return String;

   --  Compare the current metadata token with a previously captured label.
   --  This is intended for command-boundary conflict checks only.
   function External_Change_Status
     (Path        : String;
      Known       : Boolean;
      Known_Label : String) return File_External_Change_Status;

   type File_Open_Status is
     (File_Open_Ok,
      File_Open_Not_Found,
      File_Open_Is_Directory,
      File_Open_Permission_Denied,
      File_Open_Read_Error,
      File_Open_Invalid_Path,
      File_Open_Decode_Error);

   --  Complete result of a path-based file-open attempt. Open_File returns
   --  this value without mutating editor state, publishing messages, or
   --  touching rendering/input subsystems.
   type File_Open_Result is record
      Status       : File_Open_Status := File_Open_Invalid_Path;
      Path         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Contents     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type File_Save_Status is
     (File_Save_Ok,
      File_Save_Invalid_Path,
      File_Save_Parent_Unavailable,
      File_Save_Is_Directory,
      File_Save_Permission_Denied,
      File_Save_Write_Error,
      File_Save_No_Current_Path);

   type File_Rename_Status is
     (File_Rename_Ok,
      File_Rename_Invalid_Source,
      File_Rename_Invalid_Target,
      File_Rename_Source_Not_Found,
      File_Rename_Source_Is_Directory,
      File_Rename_Target_Exists,
      File_Rename_Permission_Denied,
      File_Rename_Error);

   type File_Delete_Status is
     (File_Delete_Ok,
      File_Delete_Invalid_Source,
      File_Delete_Source_Not_Found,
      File_Delete_Source_Is_Directory,
      File_Delete_Permission_Denied,
      File_Delete_Error);

   type File_Copy_Status is
     (File_Copy_Ok,
      File_Copy_Invalid_Source,
      File_Copy_Invalid_Target,
      File_Copy_Source_Not_Found,
      File_Copy_Source_Is_Directory,
      File_Copy_Target_Exists,
      File_Copy_Permission_Denied,
      File_Copy_Error);

   type File_Move_Status is
     (File_Move_Ok,
      File_Move_Invalid_Source,
      File_Move_Invalid_Target,
      File_Move_Source_Not_Found,
      File_Move_Source_Is_Directory,
      File_Move_Target_Exists,
      File_Move_Permission_Denied,
      File_Move_Error);

   --  Complete result of a path-based save attempt. Save_File writes the
   --  supplied contents to disk and returns this value without mutating
   --  editor state or publishing messages.
   type File_Save_Result is record
      Status       : File_Save_Status := File_Save_Invalid_Path;
      Path         : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   --  Complete result of a path-based filesystem rename attempt.
   --  Rename_File renames an existing regular file to a non-existing
   --  explicit target path and returns this value without mutating editor
   --  state or publishing messages.
   type File_Rename_Result is record
      Status       : File_Rename_Status := File_Rename_Invalid_Target;
      Source_Path  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Target_Path  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   --  Complete result of a path-based filesystem delete attempt.
   --  Delete_File deletes an existing regular file and returns this value
   --  without mutating editor state or publishing messages.
   type File_Delete_Result is record
      Status       : File_Delete_Status := File_Delete_Invalid_Source;
      Source_Path  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   --  Complete result of a path-based filesystem copy attempt.
   --  Copy_File copies an existing regular file to a non-existing explicit
   --  target path and returns this value without mutating editor state,
   --  publishing messages, or writing buffer memory.
   type File_Copy_Result is record
      Status       : File_Copy_Status := File_Copy_Invalid_Target;
      Source_Path  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Target_Path  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   --  Complete result of a path-based filesystem move attempt.
   --  Move_File moves an existing regular file to a non-existing explicit
   --  target path and returns this value without mutating editor state,
   --  publishing messages, or writing buffer memory.
   type File_Move_Result is record
      Status       : File_Move_Status := File_Move_Invalid_Target;
      Source_Path  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Target_Path  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   --  Read and normalize a regular text file. Empty paths, missing paths,
   --  directories, non-regular files, embedded NUL bytes, and invalid UTF-8
   --  are reported through File_Open_Result instead of exceptions.
   --  @param Path host filesystem path to open
   --  @return file-open result carrying status, display name, contents, and error text
   function Open_File
     (Path : String) return File_Open_Result;

   --  Test whether a file-open result represents a successful read.
   --  @param Result file-open result to inspect
   --  @return True only when Result.Status is File_Open_Ok
   function Is_Success
     (Result : File_Open_Result) return Boolean;

   --  Test whether a save result represents a successful write.
   --  @param Result save result to inspect
   --  @return True only when Result.Status is File_Save_Ok
   function Is_Success
     (Result : File_Save_Result) return Boolean;

   --  Test whether a rename result represents a successful filesystem rename.
   --  @param Result rename result to inspect
   --  @return True only when Result.Status is File_Rename_Ok
   function Is_Success
     (Result : File_Rename_Result) return Boolean;

   --  Test whether a delete result represents a successful filesystem delete.
   --  @param Result delete result to inspect
   --  @return True only when Result.Status is File_Delete_Ok
   function Is_Success
     (Result : File_Delete_Result) return Boolean;

   --  Test whether a copy result represents a successful filesystem copy.
   --  @param Result copy result to inspect
   --  @return True only when Result.Status is File_Copy_Ok
   function Is_Success
     (Result : File_Copy_Result) return Boolean;

   --  Test whether a move result represents a successful filesystem move.
   --  @param Result move result to inspect
   --  @return True only when Result.Status is File_Move_Ok
   function Is_Success
     (Result : File_Move_Result) return Boolean;

   --  Convert a file-open result into a stable user-facing reason string.
   --  @param Result file-open result to describe
   --  @return concise success or failure message
   function Status_Message
     (Result : File_Open_Result) return String;

   --  Convert a save result into a stable user-facing reason string.
   --  @param Result save result to describe
   --  @return concise success or failure message
   function Status_Message
     (Result : File_Save_Result) return String;

   --  Convert a rename result into a stable reason string.
   --  @param Result rename result to describe
   --  @return concise success or failure message
   function Status_Message
     (Result : File_Rename_Result) return String;

   --  Convert a delete result into a stable reason string.
   --  @param Result delete result to describe
   --  @return concise success or failure message
   function Status_Message
     (Result : File_Delete_Result) return String;

   --  Convert a copy result into a stable reason string.
   --  @param Result copy result to describe
   --  @return concise success or failure message
   function Status_Message
     (Result : File_Copy_Result) return String;

   --  Return True only when Path names an existing regular file that the
   --  host reports as writable.  This helper performs no writes and is used
   --  by preview-first replacement flows to fail before dirtying buffers
   --  whose backing files cannot later be saved.
   --  @param Path host filesystem path to an existing file
   --  @return True when the file exists, is ordinary, and appears writable
   function Existing_File_Is_Writable
     (Path : String) return Boolean;

   --  Return the canonical host path for an existing regular file when
   --  the platform can resolve it; otherwise return Path unchanged.
   --  This is used only for explicit file-open/save identity after the
   --  target has passed normal path validation.
   --  @param Path host filesystem path
   --  @return canonical path for an existing regular file, or Path on failure
   function Canonical_Path_For_Existing_File
     (Path : String) return String;

   --  Derive a project-neutral display name from a host path.
   --  @param Path host filesystem path
   --  @return basename-style display name, or Untitled for an empty path
   function Display_Name_For_Path
     (Path : String) return String;

   --  Write the supplied current buffer contents to a regular file path.
   --  @param Path host filesystem path to write
   --  @param Contents serialized buffer text to write as bytes
   --  @return save result carrying status, display name, and error text
   function Save_File
     (Path     : String;
      Contents : String) return File_Save_Result;

   --  Rename an existing regular file to a non-existing explicit target path.
   --  This helper performs no editor-state mutation and never writes buffer text.
   --  @param Source host filesystem path to the existing backing file
   --  @param Target explicit host filesystem destination path
   --  @return rename result carrying target display name and failure status
   function Rename_File
     (Source : String;
      Target : String) return File_Rename_Result;

   --  Delete an existing regular file. This helper performs no editor-state
   --  mutation and never writes, renames, moves to trash, or snapshots text.
   --  @param Source host filesystem path to the existing backing file
   --  @return delete result carrying source display name and failure status
   function Delete_File
     (Source : String) return File_Delete_Result;

   --  Copy an existing regular file to a non-existing explicit target path.
   --  This helper performs no editor-state mutation and never writes buffer text.
   --  @param Source host filesystem path to the existing backing file
   --  @param Target explicit host filesystem destination path
   --  @return copy result carrying target display name and failure status
   function Copy_File
     (Source : String;
      Target : String) return File_Copy_Result;

   --  Move an existing regular file to a non-existing explicit target path.
   --  This helper performs no editor-state mutation and never writes buffer text.
   --  @param Source host filesystem path to the existing backing file
   --  @param Target explicit host filesystem destination path
   --  @return move result carrying target display name and failure status
   function Move_File
     (Source : String;
      Target : String) return File_Move_Result;

   function Load_File
     (Path : String;
      S    : in out Editor.State.State_Type) return File_Status;

   function Save_File
     (Path : String;
      S    : in out Editor.State.State_Type) return File_Status;

end Editor.Files;

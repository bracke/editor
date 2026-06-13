with Editor.Buffers;
with Editor.File_Tree;
with Editor.State;

package Editor.Lifecycle_Guidance is

   --  Return compact, non-mutating file lifecycle guidance for the active
   --  buffer or currently focused lifecycle surface.  The text is a projection
   --  from in-memory editor state and command availability only; it performs no
   --  filesystem access.
   function Status_Bar_Hint
     (S : Editor.State.State_Type) return String;

   --  Return compact guidance for a selected open-buffer row.  The hint never
   --  activates or closes the row; it only mirrors real command availability.
   function Open_Buffer_Row_Hint
     (S       : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary) return String;

   --  Return compact guidance for a selected File Tree row.  Already-open files
   --  are described as focus targets, never reload targets.  The function only
   --  reads the scanned in-memory tree and open-buffer registry.
   function File_Tree_Row_Hint
     (S    : Editor.State.State_Type;
      Node : Editor.File_Tree.File_Tree_Node_Summary) return String;

end Editor.Lifecycle_Guidance;

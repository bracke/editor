with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Editor.File_Tree is

   type File_Tree_Node_Id is new Natural;
   No_File_Tree_Node : constant File_Tree_Node_Id := 0;

   type File_Tree_Node_Kind is
     (Directory_Node,
      File_Node);

   type File_Tree_Scan_Status is
     (File_Tree_Scan_Ok,
      File_Tree_No_Project,
      File_Tree_Invalid_Root,
      File_Tree_Root_Not_Found,
      File_Tree_Root_Not_Directory,
      File_Tree_Permission_Denied,
      File_Tree_Read_Error);

   type File_Tree_Node_Summary is record
      Id            : File_Tree_Node_Id := No_File_Tree_Node;
      Parent        : File_Tree_Node_Id := No_File_Tree_Node;
      Kind          : File_Tree_Node_Kind := File_Node;
      Name          : Ada.Strings.Unbounded.Unbounded_String;
      Absolute_Path : Ada.Strings.Unbounded.Unbounded_String;
      Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
      Depth         : Natural := 0;
      Is_Expanded   : Boolean := False;
      Has_Children  : Boolean := False;
   end record;

   type Visible_File_Tree_Row is record
      Node_Id : File_Tree_Node_Id := No_File_Tree_Node;
      Depth   : Natural := 0;
   end record;

   type File_Tree_State is private;

   type File_Tree_Scan_Result is record
      Status       : File_Tree_Scan_Status := File_Tree_No_Project;
      Root_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Node_Count   : Natural := 0;
      Error_Text   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   --  Clear all scanned nodes, expansion state, visible rows, and scan status.
   --  @param Tree file tree state to reset
   procedure Clear
     (Tree : in out File_Tree_State);

   --  Return whether the file tree has no scanned root node.
   --  @param Tree file tree state to query
   --  @return True when Tree contains no nodes
   function Is_Empty
     (Tree : File_Tree_State) return Boolean;

   --  Return the root node id for the current scan.
   --  @param Tree file tree state to query
   --  @return root node id, or No_File_Tree_Node when empty
   function Root
     (Tree : File_Tree_State) return File_Tree_Node_Id;

   --  Test whether Id names a node in the current scan.
   --  @param Tree file tree state to query
   --  @param Id candidate file tree node id
   --  @return True when Id is present in Tree
   function Contains
     (Tree : File_Tree_State;
      Id   : File_Tree_Node_Id) return Boolean;

   --  Return a public summary for Id.
   --  @param Tree file tree state to query
   --  @param Id node id to summarize
   --  @return node summary, or a default summary for an invalid id
   function Node
     (Tree : File_Tree_State;
      Id   : File_Tree_Node_Id) return File_Tree_Node_Summary;

   --  Return the number of nodes in the current scan.
   --  @param Tree file tree state to query
   --  @return number of file tree nodes
   function Node_Count
     (Tree : File_Tree_State) return Natural;

   --  Return the number of file nodes in the current scan.
   --  Directory nodes, including the project root, are excluded.
   --  @param Tree file tree state to query
   --  @return number of project file nodes available to quick-open style users
   function File_Node_Count
     (Tree : File_Tree_State) return Natural;

   --  Return the number of expanded directory nodes in the current scan.
   --  @param Tree file tree state to query
   --  @return count of nodes whose expansion flag is set
   function Expanded_Node_Count
     (Tree : File_Tree_State) return Natural;

   --  Return the one-based file-node summary in deterministic scan order.
   --  Directory nodes are skipped; out-of-range indexes return a default summary.
   --  @param Tree file tree state to query
   --  @param Index one-based file-node index
   --  @return file node summary, or a default summary when Index is out of range
   function File_Node_At
     (Tree  : File_Tree_State;
      Index : Positive) return File_Tree_Node_Summary;

   --  Test whether Id names a file node in the current scan.
   --  @param Tree file tree state to query
   --  @param Id candidate node id
   --  @return True only when Id is present and is a file node
   function Is_File_Node
     (Tree : File_Tree_State;
      Id   : File_Tree_Node_Id) return Boolean;

   --  Return the number of flattened visible rows.
   --  @param Tree file tree state to query
   --  @return visible row count derived from expansion state
   function Visible_Row_Count
     (Tree : File_Tree_State) return Natural;

   --  Return the flattened visible row at a one-based index.
   --  @param Tree file tree state to query
   --  @param Index one-based visible row index
   --  @return visible row, or a default row for an out-of-range index
   function Visible_Row
     (Tree  : File_Tree_State;
      Index : Positive) return Visible_File_Tree_Row;

   --  Return the node id at a one-based visible row index.
   --  @param Tree file tree state to query
   --  @param Row one-based visible row index
   --  @param Found set True when Row maps to a visible node
   --  @return node id, or No_File_Tree_Node when not found
   function Node_At_Visible_Row
     (Tree  : File_Tree_State;
      Row   : Positive;
      Found : out Boolean) return File_Tree_Node_Id;

   --  Find a node by exact absolute path or project-relative path.
   --  @param Tree file tree state to query
   --  @param Path absolute or project-relative path to find
   --  @param Found set True when a node has the requested path
   --  @return matching node id, or No_File_Tree_Node when not found
   function Find_By_Path
     (Tree  : File_Tree_State;
      Path  : String;
      Found : out Boolean) return File_Tree_Node_Id;

   --  Toggle expansion for a directory node.
   --  Files and invalid ids are deterministic no-ops.
   --  @param Tree file tree state to mutate
   --  @param Id directory node id to toggle
   procedure Toggle_Expanded
     (Tree : in out File_Tree_State;
      Id   : File_Tree_Node_Id);

   --  Set expansion for a directory node.
   --  Files and invalid ids are deterministic no-ops.
   --  @param Tree file tree state to mutate
   --  @param Id directory node id to update
   --  @param Expanded new expansion state
   procedure Set_Expanded
     (Tree     : in out File_Tree_State;
      Id       : File_Tree_Node_Id;
      Expanded : Boolean);

   --  Collapse every directory node and rebuild visible rows.
   --  @param Tree file tree state to mutate
   procedure Collapse_All
     (Tree : in out File_Tree_State);

   --  Expand all parent directories for Id, leaving Id itself unchanged.
   --  Invalid ids are deterministic no-ops.
   --  @param Tree file tree state to mutate
   --  @param Id node whose ancestors should become visible
   procedure Expand_Ancestors
     (Tree : in out File_Tree_State;
      Id   : File_Tree_Node_Id);

   --  Expand all parent directories for scanned file nodes.
   --  Invalid or empty trees are deterministic no-ops.
   --  @param Tree file tree state to mutate
   procedure Expand_File_Ancestors
     (Tree : in out File_Tree_State);

   --  Return a stable UI label for the node kind.
   --  @param Kind file tree node kind
   --  @return directory or file
   function Kind_Label
     (Kind : File_Tree_Node_Kind) return String;


   --  Copy directory expansion state from Source into Tree by stable paths.
   --  Directories that no longer exist in Tree keep the refreshed scan default.
   --  @param Tree refreshed file tree state to update
   --  @param Source previous file tree state whose expansion state should survive
   procedure Preserve_Expanded_Paths_From
     (Tree   : in out File_Tree_State;
      Source : File_Tree_State);

   --  Rebuild the flattened visible-row cache from the node expansion state.
   --  @param Tree file tree state to mutate
   procedure Rebuild_Visible_Rows
     (Tree : in out File_Tree_State);

   --  Scan a project root into a deterministic file tree model.
   --  @param Root_Path host filesystem directory path to scan
   --  @return file tree state containing a root node on success
   function Scan_Project
     (Root_Path : String) return File_Tree_State;

   --  Return the status of the most recent scan that produced Tree.
   --  @param Tree file tree state to query
   --  @return scan result summary
   function Scan_Status
     (Tree : File_Tree_State) return File_Tree_Scan_Result;

private
   package Node_Id_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => File_Tree_Node_Id);

   type File_Tree_Node_Record is record
      Id            : File_Tree_Node_Id := No_File_Tree_Node;
      Parent        : File_Tree_Node_Id := No_File_Tree_Node;
      Kind          : File_Tree_Node_Kind := File_Node;
      Name          : Ada.Strings.Unbounded.Unbounded_String;
      Absolute_Path : Ada.Strings.Unbounded.Unbounded_String;
      Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
      Depth         : Natural := 0;
      Is_Expanded   : Boolean := False;
      Children      : Node_Id_Vectors.Vector;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => File_Tree_Node_Record);

   package Visible_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Visible_File_Tree_Row);

   type File_Tree_State is record
      Nodes        : Node_Vectors.Vector;
      Visible_Rows : Visible_Row_Vectors.Vector;
      Root_Id      : File_Tree_Node_Id := No_File_Tree_Node;
      Next_Id      : File_Tree_Node_Id := 1;
      Last_Result  : File_Tree_Scan_Result;
   end record;

end Editor.File_Tree;

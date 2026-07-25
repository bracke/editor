with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Language_Model.Hashing; use Editor.Ada_Language_Model.Hashing;
with Editor.Ada_Language_Model.Symbols; use Editor.Ada_Language_Model.Symbols;
with Editor.Ada_Language_Model.Generic_Metadata; use Editor.Ada_Language_Model.Generic_Metadata;
with Editor.Ada_Language_Model.Representation_Metadata; use Editor.Ada_Language_Model.Representation_Metadata;
with Editor.Ada_Language_Model.Diagnostics; use Editor.Ada_Language_Model.Diagnostics;
with Editor.Ada_Language_Model.Visibility; use Editor.Ada_Language_Model.Visibility;
with Editor.Ada_Language_Model.Syntax_Attachment; use Editor.Ada_Language_Model.Syntax_Attachment;

package body Editor.Ada_Language_Model.Syntax_Attachment is

   pragma Suppress (Overflow_Check);

   procedure Set_Syntax_Tree
     (Analysis : in out Analysis_Result;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type)
   is
   begin
      Analysis.Syntax_Tree_Value := Tree;
      Analysis.Syntax_Tree_Aware := Editor.Ada_Syntax_Tree.Has_Nodes (Tree);
      Analysis.Result_Fingerprint :=
        (Analysis.Result_Fingerprint * 65599
         + Editor.Ada_Syntax_Tree.Fingerprint (Tree) + 37) mod Natural'Last;
   end Set_Syntax_Tree;

   function Has_Syntax_Tree (Analysis : Analysis_Result) return Boolean is
   begin
      return Analysis.Syntax_Tree_Aware;
   end Has_Syntax_Tree;

   function Syntax_Tree_Node_Count (Analysis : Analysis_Result) return Natural is
   begin
      return Editor.Ada_Syntax_Tree.Node_Count (Analysis.Syntax_Tree_Value);
   end Syntax_Tree_Node_Count;

   function Syntax_Tree_Root_Kind
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Node_Kind
   is
   begin
      if not Analysis.Syntax_Tree_Aware then
         return Editor.Ada_Syntax_Tree.Node_Unknown;
      end if;
      return Editor.Ada_Syntax_Tree.Node
        (Analysis.Syntax_Tree_Value,
         Editor.Ada_Syntax_Tree.Root (Analysis.Syntax_Tree_Value)).Kind;
   end Syntax_Tree_Root_Kind;

   function Syntax_Tree_Fingerprint (Analysis : Analysis_Result) return Natural is
   begin
      return Editor.Ada_Syntax_Tree.Fingerprint (Analysis.Syntax_Tree_Value);
   end Syntax_Tree_Fingerprint;

   function Syntax_Tree
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Tree_Type
   is
   begin
      return Analysis.Syntax_Tree_Value;
   end Syntax_Tree;

   function Fingerprint (Analysis : Analysis_Result) return Natural is
   begin
      return Analysis.Result_Fingerprint;
   end Fingerprint;


end Editor.Ada_Language_Model.Syntax_Attachment;

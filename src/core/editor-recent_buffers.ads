with Ada.Containers.Vectors;

package Editor.Recent_Buffers is

   subtype Buffer_Key is Natural;
   No_Buffer_Key : constant Buffer_Key := 0;

   type Recent_Buffer_State is private;

   procedure Clear (State : in out Recent_Buffer_State);

   procedure Mark_Activated
     (State              : in out Recent_Buffer_State;
      Id                 : Buffer_Key;
      Preserve_Traversal : Boolean := False);

   procedure Remove
     (State : in out Recent_Buffer_State;
      Id    : Buffer_Key);

   function Count (State : Recent_Buffer_State) return Natural;

   function Contains
     (State : Recent_Buffer_State;
      Id    : Buffer_Key) return Boolean;

   function Id_At
     (State : Recent_Buffer_State;
      Index : Positive) return Buffer_Key;

   function Has_Previous
     (State  : Recent_Buffer_State;
      Active : Buffer_Key) return Boolean;

   function Has_Next (State : Recent_Buffer_State) return Boolean;

   function Previous_Target
     (State  : in out Recent_Buffer_State;
      Active : Buffer_Key) return Buffer_Key;

   function Next_Target
     (State : in out Recent_Buffer_State) return Buffer_Key;

   procedure Clear_Traversal (State : in out Recent_Buffer_State);

private
   package Buffer_Key_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Buffer_Key);

   type Recent_Buffer_State is record
      Order            : Buffer_Key_Vectors.Vector;
      Traversal_Order  : Buffer_Key_Vectors.Vector;
      Traversal_Active : Boolean := False;
      Traversal_Index  : Natural := 0;
   end record;

end Editor.Recent_Buffers;

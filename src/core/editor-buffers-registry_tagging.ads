package Editor.Buffers.Registry_Tagging is

   function Is_Buffer_Pinned
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Has_Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   procedure Set_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Label    : String);

   procedure Clear_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Has_Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   procedure Set_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Note     : String);

   procedure Clear_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Has_Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean;

   function Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String;

   procedure Assign_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Name     : String);

   procedure Clear_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   function Has_Buffer_Groups
     (Registry : Buffer_Registry) return Boolean;

   function Has_Active_Buffer_Group
     (Registry : Buffer_Registry) return Boolean;

   function Active_Buffer_Group
     (Registry : Buffer_Registry) return String;

   function First_Buffer_In_Group
     (Registry : Buffer_Registry;
      Name     : String) return Buffer_Id;

   procedure Set_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Name     : String);

   procedure Clear_Active_Buffer_Group
     (Registry : in out Buffer_Registry);

   procedure Cycle_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Forward  : Boolean);

   procedure Pin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   procedure Unpin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

   procedure Toggle_Buffer_Pin
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id);

end Editor.Buffers.Registry_Tagging;

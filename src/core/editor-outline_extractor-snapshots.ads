package Editor.Outline_Extractor.Snapshots is

   function Make_Snapshot
     (Text : String) return Buffer_Text_Snapshot;

   function Make_Snapshot
     (Text         : String;
      Buffer_Label : String) return Buffer_Text_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Active_Buffer_Token   : Natural;
      Buffer_Revision       : Natural;
      Lifecycle_Generation  : Natural;
      Request_Token         : Natural) return Buffer_Text_Snapshot;

   function Make_Snapshot
     (Text                  : String;
      Buffer_Label          : String;
      Active_Buffer_Token   : Natural;
      Buffer_Revision       : Natural;
      Lifecycle_Generation  : Natural;
      Request_Token         : Natural) return Buffer_Text_Snapshot;

   function Identity
     (Snapshot : Buffer_Text_Snapshot)
      return Editor.Outline.Outline_Snapshot_Identity;

   function Status
     (Result : Extraction_Result) return Extraction_Status;

   function Failure
     (Result : Extraction_Result) return Extraction_Failure_Kind;

   function Item_Count
     (Result : Extraction_Result) return Natural;

   function Identity
     (Result : Extraction_Result)
      return Editor.Outline.Outline_Snapshot_Identity;

   function Is_Success
     (Result : Extraction_Result) return Boolean;

   function Fingerprint
     (Result : Extraction_Result) return Natural;

end Editor.Outline_Extractor.Snapshots;

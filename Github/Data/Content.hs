{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE OverloadedStrings  #-}
-----------------------------------------------------------------------------
-- |
-- License     :  BSD-3-Clause
-- Maintainer  :  Oleg Grenrus <oleg.grenrus@iki.fi>
--
module Github.Data.Content where

import Prelude        ()
import Prelude.Compat

import Control.DeepSeq          (NFData (..))
import Control.DeepSeq.Generics (genericRnf)
import Data.Aeson.Compat        (FromJSON (..), Value (..), withObject,
                                 withText, (.:))
import Data.Binary.Orphans      (Binary)
import Data.Data                (Data, Typeable)
import Data.Text                (Text)
import Data.Vector              (Vector)
import GHC.Generics             (Generic)

import qualified Data.Text as T

data Content
  = ContentFile !ContentFileData
  | ContentDirectory !(Vector ContentItem)
 deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData Content where rnf = genericRnf
instance Binary Content

data ContentFileData = ContentFileData {
   contentFileInfo     :: !ContentInfo
  ,contentFileEncoding :: !Text
  ,contentFileSize     :: !Int
  ,contentFileContent  :: !Text
} deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData ContentFileData where rnf = genericRnf
instance Binary ContentFileData

-- | An item in a directory listing.
data ContentItem = ContentItem {
   contentItemType :: !ContentItemType
  ,contentItemInfo :: !ContentInfo
} deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData ContentItem where rnf = genericRnf
instance Binary ContentItem

data ContentItemType = ItemFile | ItemDir
  deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData ContentItemType where rnf = genericRnf
instance Binary ContentItemType

-- | Information common to both kinds of Content: files and directories.
data ContentInfo = ContentInfo {
   contentName    :: !Text
  ,contentPath    :: !Text
  ,contentSha     :: !Text
  ,contentUrl     :: !Text
  ,contentGitUrl  :: !Text
  ,contentHtmlUrl :: !Text
} deriving (Show, Data, Typeable, Eq, Ord, Generic)

instance NFData ContentInfo where rnf = genericRnf
instance Binary ContentInfo

instance FromJSON Content where
  parseJSON o@(Object _) = ContentFile <$> parseJSON o
  parseJSON (Array os) = ContentDirectory <$> traverse parseJSON os
  parseJSON _ = fail "Could not build a Content"

instance FromJSON ContentFileData where
  parseJSON = withObject "ContentFileData" $ \o ->
    ContentFileData <$> parseJSON (Object o)
                    <*> o .: "encoding"
                    <*> o .: "size"
                    <*> o .: "content"

instance FromJSON ContentItem where
  parseJSON = withObject "ContentItem" $ \o ->
    ContentItem <$> o .: "type"
                <*> parseJSON (Object o)

instance FromJSON ContentItemType where
  parseJSON = withText "ContentItemType" $ \t ->
      case t of
          "file" -> return ItemFile
          "dir"  -> return ItemDir
          _      -> fail $ "Invalid ContentItemType: " ++ T.unpack t

instance FromJSON ContentInfo where
  parseJSON = withObject "ContentInfo" $ \o ->
    ContentInfo <$> o .: "name"
                <*> o .: "path"
                <*> o .: "sha"
                <*> o .: "url"
                <*> o .: "git_url"
                <*> o .: "html_url"

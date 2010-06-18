{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}


module Snap.StaticPages.Internal.Types 
  ( module Snap.StaticPages.Internal.Exception
  , Post(..)
  , getPostTime
  , ContentMap
  , ContentItem(..)
  , StaticPagesState(..)
  )
where

------------------------------------------------------------------------------
import           Data.ByteString.Char8 (ByteString)
import           Data.Map (Map)
import           Data.Maybe
import           Data.Time.LocalTime
import           Snap.Types
import qualified Text.Atom.Feed as Atom
import           Text.Templating.Heist
------------------------------------------------------------------------------
import           Snap.StaticPages.Internal.Exception
import           Snap.StaticPages.Internal.Time
import           Snap.StaticPages.Internal.Util.ExcludeList

-- to make things super-easy on us, we'll define our internal post
-- format to be the same as our Atom feed.
newtype Post = Post { unPost :: Atom.Entry }
  deriving (Show)


getPostTime :: Post -> ZonedTime
getPostTime (Post p) = parseAtomTime $ fromMaybe upd pub
  where
    pub = Atom.entryPublished p
    upd = Atom.entryUpdated p


type ContentMap = Map ByteString ContentItem

data ContentItem =
       ContentPost Post                        -- ^ a post
     | ContentDirectory ByteString ContentMap  -- ^ a path prefix + content
                                               --   mapping
     | ContentStatic FilePath                  -- ^ a static file
  deriving (Show)


{-|

StaticPagesState is an opaque data type that holds StaticPages internal state.

-}
data StaticPagesState = StaticPagesState
    { staticPagesPath      :: FilePath           -- ^ path on disk
    , staticPagesSiteURL   :: String             -- ^ site URL, minus slash
                                                 --   (e.g. http://foo.com)
    , staticPagesBaseURL   :: String             -- ^ base URL of content section,
                                                 --   e.g. "/posts"
    , staticPagesPostMap   :: ContentMap         -- ^ content
    , staticPagesTemplates :: TemplateState Snap -- ^ templates
    , staticPagesFeedInfo  :: Atom.Feed          -- ^ feed info

    , staticPagesFeedExcludes :: ExcludeList     -- ^ these URLs won't appear in
                                                 -- feeds or in post listings

    , staticPagesExtraTmpl :: TemplateState Snap -> Snap (TemplateState Snap)
                                         -- ^ extra template variables get
                                         --   inserted here
    }
